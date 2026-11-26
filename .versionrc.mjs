const packageFile = filename => ({ filename, type: "json" });

export default {
	header: "# Changelog\n\nAll notable changes to this project will be documented in this file.\n",
	packageFiles: [packageFile("package.json")],
	bumpFiles: [
		packageFile("package.json"),
		packageFile("package-lock.json"),
		packageFile("jamserve/package.json"),
		packageFile("jamserve/package-lock.json"),
		packageFile("jamberry/package.json"),
		packageFile("jamberry/package-lock.json")
	],
	writerOpts: {
		preamblePartial: context =>
			context.commitGroups?.length || context.noteGroups?.length
				? (context.preamble ?? "")
				: "### Maintenance\n\n* dependency and build updates only, no user facing changes"
	}
};
