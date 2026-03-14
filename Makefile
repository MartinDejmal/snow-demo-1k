# Makefile for C64 Snow Demo
# Requires: acme assembler (sudo apt-get install acme)

ACME    = acme
SRC     = snow.asm
PRG     = snow.prg

.PHONY: all clean size

all: $(PRG)

$(PRG): $(SRC)
	$(ACME) $(SRC)
	@echo "Build OK: $(PRG)"

size: $(PRG)
	@SIZE=$$(wc -c < $(PRG)); \
	echo "Binary size: $$SIZE bytes (limit 1024)"; \
	if [ $$SIZE -le 1024 ]; then \
		echo "  OK - fits within 1K"; \
	else \
		echo "  FAIL - exceeds 1K by $$((SIZE - 1024)) bytes"; \
		exit 1; \
	fi

clean:
	rm -f $(PRG)
