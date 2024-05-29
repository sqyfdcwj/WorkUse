Sed snippets

Delete **X**th line<br>
> sed '**X**d' test.txt 

Delete last line<br>
> sed '$d' test.txt

Delete lines from range **X** to **Y**<br>
> sed '**X**, **Y**d' test.txt

Delete lines from Xth to the last line
> sed '**X**, $d' test.txt

Delete lines which matches pattern
> sed '/**PATTERN**/d' test.txt

Delete **X**th last line
> sed "$(expr \`wc -l < test.txt | bc\` + 2 - **X**)d" test.txt

