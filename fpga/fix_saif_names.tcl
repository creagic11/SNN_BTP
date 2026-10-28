# Tcl twin of scripts/fix_saif_names.py (runs inside Vivado, no Python needed on the laptop).
# xsim writes escaped netlist identifiers as  \\name\[i\]_n_0\   and escaped buses as  \\name\ \[k\] ;
# read_saif matches  name\[i\]_n_0  and  name\[k\] . Lines with "(null)" scope names cannot be parsed and are
# dropped. Returns {bus scalar dropped left_escaped paren_balance}.
proc fix_saif_names {src dst} {
    set fi [open $src r]; set fo [open $dst w]
    set nb 0; set ns 0; set nd 0; set nl 0; set bal 0
    while {[gets $fi ln] >= 0} {
        if {[string first "(null" $ln] >= 0} { incr nd; continue }
        if {[regsub {\(\\\\([^ ]+)\\ \\\[([0-9]+)\\\] \(T0} $ln {(\1\\[\2\\] (T0} ln2]} { incr nb
        } elseif {[regsub {\(\\\\([^ ]+)\\  \(T0} $ln {(\1 (T0} ln2]} { incr ns
        } else { set ln2 $ln }
        if {[string first "(\\\\" $ln2] >= 0} { incr nl }
        incr bal [expr {[regexp -all {\(} $ln2] - [regexp -all {\)} $ln2]}]
        puts $fo $ln2
    }
    close $fi; close $fo
    return [list $nb $ns $nd $nl $bal]
}
if {[info exists argv0] && [file tail $argv0] eq "fix_saif_names.tcl" && [llength $argv] == 2} {
    puts [fix_saif_names [lindex $argv 0] [lindex $argv 1]]
}
