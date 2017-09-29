all:
	@./maketoc > 00_Zsh-开发指南（目录）.md
	@echo '# Zsh 开发指南' > README.md
	@echo >> README.md
	@echo '[目录](00_Zsh-开发指南（目录）.md)' >> README.md
	@cat 00_Zsh-开发指南（目录）.md | grep '^## ' | sed 's/^## /\n/g' >> README.md
