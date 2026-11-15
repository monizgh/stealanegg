const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const sourcePath = path.join(root, "src", "StealAnEgg.server.luau");
const clientPath = path.join(root, "src", "UIController.client.luau");
const outPath = path.join(root, "StealAnEgg.rbxlx");

const source = fs.readFileSync(sourcePath, "utf8");
const clientSource = fs.readFileSync(clientPath, "utf8");

for (const [name, contents] of [["server", source], ["client", clientSource]]) {
    if (contents.includes("]]>")) {
        throw new Error(`${name} source contains the CDATA terminator and cannot be embedded`);
    }
}

function cdata(contents) {
    return `<![CDATA[${contents}]]>`;
}

function patchScript(xml, className, scriptName, contents) {
    const tag = `<Item class="${className}"`;
    const nameTag = `<string name="Name">${scriptName}</string>`;
    const nameIndex = xml.indexOf(nameTag);
    if (nameIndex === -1) {
        throw new Error(`Could not find "${scriptName}" in the place file`);
    }

    const openIndex = xml.lastIndexOf(tag, nameIndex);
    const closeIndex = xml.indexOf("</Item>", nameIndex);
    if (openIndex === -1 || closeIndex === -1) {
        throw new Error(`Could not bracket the ${className} item for "${scriptName}"`);
    }

    const block = xml.slice(openIndex, closeIndex);
    const sourcePattern = /(<ProtectedString name="Source">)([\s\S]*?)(<\/ProtectedString>)/;
    if (!sourcePattern.test(block)) {
        throw new Error(`No Source property in ${className} "${scriptName}"`);
    }
    if ((block.match(sourcePattern) || [])[0] === undefined) {
        throw new Error(`Could not read Source property in ${className} "${scriptName}"`);
    }

    const replacement = head => head;
    void replacement;
    const patchedBlock = block.replace(sourcePattern, (_whole, head, _body, tail) => head + cdata(contents) + tail);
    return xml.slice(0, openIndex) + patchedBlock + xml.slice(closeIndex);
}

if (fs.existsSync(outPath)) {
    const original = fs.readFileSync(outPath, "utf8");
    if (!original.includes("UIMegaPack")) {
        throw new Error(
            "StealAnEgg.rbxlx does not contain UIMegaPack. Refusing to overwrite the existing place; " +
                "import the pack first or delete the file intentionally."
        );
    }
    const backupPath = outPath + ".bak";
    if (!fs.existsSync(backupPath)) {
        fs.writeFileSync(backupPath, original);
    }

    let patched = patchScript(original, "Script", "StealAnEgg", source);
    patched = patchScript(patched, "LocalScript", "UIController", clientSource);
    if (!patched.includes("UIMegaPack")) {
        throw new Error("Patch would remove UIMegaPack; aborted");
    }
    fs.writeFileSync(outPath, patched);
    console.log(`Patched ${outPath} in place (${patched.length} bytes, backup ${path.basename(backupPath)})`);
} else {
    const xml = `<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
\t<External>null</External>
\t<External>nil</External>
\t<Item class="Workspace" referent="RBX0">
\t\t<Properties>
\t\t\t<string name="Name">Workspace</string>
\t\t</Properties>
\t</Item>
\t<Item class="Lighting" referent="RBX1">
\t\t<Properties>
\t\t\t<string name="Name">Lighting</string>
\t\t</Properties>
\t</Item>
\t<Item class="ServerScriptService" referent="RBX2">
\t\t<Properties>
\t\t\t<string name="Name">ServerScriptService</string>
\t\t</Properties>
\t\t<Item class="Script" referent="RBX3">
\t\t\t<Properties>
\t\t\t\t<string name="Name">StealAnEgg</string>
\t\t\t\t<bool name="Disabled">false</bool>
\t\t\t\t<ProtectedString name="Source">${cdata(source)}</ProtectedString>
\t\t\t</Properties>
\t\t</Item>
\t</Item>
\t<Item class="StarterPlayer" referent="RBX4">
\t\t<Properties>
\t\t\t<string name="Name">StarterPlayer</string>
\t\t</Properties>
\t\t<Item class="StarterPlayerScripts" referent="RBX5">
\t\t\t<Properties>
\t\t\t\t<string name="Name">StarterPlayerScripts</string>
\t\t\t</Properties>
\t\t\t<Item class="LocalScript" referent="RBX6">
\t\t\t\t<Properties>
\t\t\t\t\t<string name="Name">UIController</string>
\t\t\t\t\t<bool name="Disabled">false</bool>
\t\t\t\t\t<ProtectedString name="Source">${cdata(clientSource)}</ProtectedString>
\t\t\t\t</Properties>
\t\t\t</Item>
\t\t</Item>
\t</Item>
</roblox>
`;
    fs.writeFileSync(outPath, xml);
    console.log(`Wrote ${outPath} (${xml.length} bytes)`);
}
