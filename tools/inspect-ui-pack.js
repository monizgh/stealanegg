const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const file = path.join(root, "StealAnEgg.rbxlx");
const lines = fs.readFileSync(file, "utf8").split(/\r?\n/);

function itemDepthStack() {
    const stack = [];
    let packOpen = -1;
    let packClose = -1;
    for (let index = 0; index < lines.length; index += 1) {
        const line = lines[index];
        if (/<Item class="/.test(line)) {
            stack.push(index);
        } else if (line.trim() === "</Item>") {
            const openIndex = stack.pop();
            if (openIndex === undefined) continue;
            let name = "";
            for (let scan = openIndex; scan < Math.min(openIndex + 400, index); scan += 1) {
                const match = lines[scan].match(/<string name="Name">([^<]*)<\/string>/);
                if (match) {
                    name = match[1];
                    break;
                }
            }
            if (name === "UIMegaPack") {
                packOpen = openIndex;
                packClose = index;
            }
        }
    }
    return { packOpen, packClose };
}

const { packOpen, packClose } = itemDepthStack();
if (packOpen < 0) {
    console.log("UIMegaPack model not found");
    process.exit(1);
}
console.log(`UIMegaPack lines ${packOpen + 1}..${packClose + 1}`);

const entries = [];
const stack = [];
let activeContent = null;

function current() {
    return stack[stack.length - 1];
}

for (let index = packOpen + 1; index < packClose; index += 1) {
    const line = lines[index];
    const trimmed = line.trim();

    const open = line.match(/<Item class="([^"]+)" referent="([^"]+)">/);
    if (open) {
        stack.push({ class: open[1], name: null, depth: stack.length, props: {} });
        continue;
    }
    if (trimmed === "</Item>") {
        const closed = stack.pop();
        if (closed) entries.push(closed);
        continue;
    }

    const item = current();
    if (!item) continue;

    if (!item.name) {
        const nameMatch = trimmed.match(/<string name="Name">([^<]*)<\/string>/);
        if (nameMatch) item.name = nameMatch[1];
    }

    const contentInline = trimmed.match(/<Content name="([^"]+)"><uri>([^<]*)<\/uri><\/Content>/);
    if (contentInline) {
        item.props[contentInline[1]] = contentInline[2];
    }
    const contentOpen = trimmed.match(/<Content name="([^"]+)">$/);
    if (contentOpen) {
        activeContent = contentOpen[1];
    } else if (trimmed === "</Content>") {
        activeContent = null;
    } else if (activeContent) {
        const uri = trimmed.match(/<uri>([^<]*)<\/uri>/);
        if (uri) item.props[activeContent] = uri[1];
    }

    for (const key of ["Text", "Visible", "Rotation", "ZIndex", "Font", "TextSize", "ImageTransparency", "BackgroundTransparency", "CornerRadius", "Thickness", "SliceScale"]) {
        const match = trimmed.match(new RegExp(`<(?:string|bool|int|float|token|UDim2|Vector2) name="${key}">([^<]*)</`));
        if (match) item.props[key] = match[1];
    }

    if (trimmed.startsWith("<Vector2 name=\"ImageRectOffset\">")) {
        const x = lines[index + 1] && lines[index + 1].match(/<X>([^<]*)<\/X>/);
        const y = lines[index + 2] && lines[index + 2].match(/<Y>([^<]*)<\/Y>/);
        item.props.ImageRectOffset = `${x ? x[1] : "?"},${y ? y[1] : "?"}`;
    }
    if (trimmed.startsWith("<Vector2 name=\"ImageRectSize\">")) {
        const x = lines[index + 1] && lines[index + 1].match(/<X>([^<]*)<\/X>/);
        const y = lines[index + 2] && lines[index + 2].match(/<Y>([^<]*)<\/Y>/);
        item.props.ImageRectSize = `${x ? x[1] : "?"},${y ? y[1] : "?"}`;
    }
    if (trimmed.startsWith("<Rect2D name=\"SliceCenter\">")) {
        const min = lines[index + 1] && lines[index + 1].match(/<min>([^<]*)<\/min>/);
        const max = lines[index + 2] && lines[index + 2].match(/<max>([^<]*)<\/max>/);
        if (min && max) item.props.SliceCenter = `${min[1]} | ${max[1]}`;
    }
}

const counts = {};
for (const entry of entries) {
    counts[entry.class] = (counts[entry.class] || 0) + 1;
}

const out = [];
out.push("CLASS COUNTS");
for (const [key, value] of Object.entries(counts).sort((a, b) => b[1] - a[1])) {
    out.push(`  ${key}: ${value}`);
}
out.push("");
out.push("TREE");
for (const entry of entries) {
    const indent = "  ".repeat(entry.depth);
    const interesting = [];
    for (const [key, value] of Object.entries(entry.props)) {
        if (value === "false" || value === "0" || value === "True" || value === "") continue;
        interesting.push(`${key}=${value}`);
    }
    const label = entry.name ? `"${entry.name}"` : "(unnamed)";
    out.push(`${indent}${entry.class} ${label}${interesting.length ? "  [" + interesting.join(" ; ") + "]" : ""}`);
}

fs.writeFileSync(path.join(root, "ui-pack-report.txt"), out.join("\n"));
console.log(out.slice(0, 150).join("\n"));
console.log(`\nWROTE ui-pack-report.txt (${entries.length} items)`);
