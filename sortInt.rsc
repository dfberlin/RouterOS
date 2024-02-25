:global sortInt do={
    :local tmp
    :local i
    :local aaa $1
    :local n [:len $aaa]
    :local swapped yes
    :if ([:typeof $aaa] = "nothing") do={
        :error ($0 . ": First argument has to be an array of int.")
    }
    :while ($swapped and ($n >= 2)) do={
        :set swapped no
        :for i from=0 to=($n - 2) do={
            :if ($aaa->$i > $aaa->($i+1)) do={
                :set tmp ($aaa->$i)
                :set ($aaa->$i) ($aaa->($i+1))
                :set ($aaa->($i+1)) $tmp
                :set swapped yes
            }
        :put ($n . ": " . $i . ": " . [:tostr $aaa])
        }
# After each iteration one more element has found its place
# at the end of the array. 
        :set n ($n - 1)
    }
    return $aaa
}
