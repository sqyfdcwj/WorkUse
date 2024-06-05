
# A sed command can specify 0, 1 or 2 addresses.
# An address can be a regex describing pattern,
# a line number, or a line addressing symbol.

/)$/ {
    N
    s/)\n{/) {/
}