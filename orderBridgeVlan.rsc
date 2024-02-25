# Script:   $orderBridgeVlan
# Purpose:  Align the order of VLANs within a bridge to the order of interfaces.
#           Practically sorting the VLAN member ports.
# Usage:    1. Copy the script on the RouterOS 7 device.
#           2. Import the script by using /import orderBridgeVlan.rsc
#           3. Invoke the script $orderBridgeVlan
#           If invoced without paramter changes are proposed in case VLAN
#           members are not in order.
#           If invoced as $orderBridgeVlan doit, changes are applied instead of
#           proposed.
:global "_arrayToCommaSeperatedString" do={
    :local element
    :local result ""
    foreach element in=$1 do={
        if ([:len $result] > 0) do={
            :set result ($result . "," . $element)
        } else={
            :set result $element
        }
    }
    return $result
}

:global "_applyChange" do={
    :global "_arrayToCommaSeperatedString"
    :local vlanIDs $1
    :local orderedPorts $2
    :local taggedUntagged $3
    :local cmd
    :set cmd  ("/interface/bridge/vlan/set " . $taggedUntagged . "=\"" . [$"_arrayToCommaSeperatedString" $orderedPorts] . "\" " \
         . "numbers=[find vlan-ids=" . [$"_arrayToCommaSeperatedString" $vlanIDs ] . "]")
    if ($4 = "doit") do={
        :put ("Applying " . $cmd)
        [:parse $cmd]
    } else={
        :put $cmd
    }
}

:global orderBridgeVlan do={
    :global "_applyChange"
    :global "_arrayToCommaSeperatedString"
    :local ifaceList
    :local ifaceIdx
    :local lenIfaceList
    :local vlanIDsIdx
    :local vlanIDs
    :local taggedPort
    :local untaggedPort
    :local lenTagged
    :local lenUntagged
    :local orderedUntaggedPort
    :local orderedTaggedPort
    :local idx
    :local changeProposed no
# We concider the interface list ordered.
# The reference interface list is constructed of bridges and ether interfaces.
    :foreach ifaceIdx in=[/interface/bridge/find] do={
        :set ifaceList ($ifaceList, [/interface/ethernet/get value-name=name number=$ifaceIdx])
    }
    :foreach ifaceIdx in=[/interface/ethernet/find] do={
        :set ifaceList ($ifaceList, [/interface/ethernet/get value-name=name number=$ifaceIdx])
    }
    :set lenIfaceList [:len $ifaceList]
    :foreach vlanIDsIdx in=[/interface/bridge/vlan/find] do={
        :set orderedUntaggedPort [:toarray ""]
        :set orderedTaggedPort [:toarray ""]
        :set vlanIDs [/interface/bridge/vlan/get value-name=vlan-ids number=$vlanIDsIdx]
        :set untaggedPort [/interface/bridge/vlan/get value-name=untagged number=[find vlan-ids=$vlanIDs]]
        :set taggedPort [/interface/bridge/vlan/get value-name=tagged number=[find vlan-ids=$vlanIDs]]
        :set lenUntagged [:len $untaggedPort]
        :set lenTagged [:len $taggedPort]

# Here we match our reference interface list against the tagged / untagged members of the current vlan-ids.
        :set idx 0
        :while (($idx < $lenIfaceList) and ([:len $orderedUntaggedPort] < $lenUntagged)) do={
            :if ([:find $untaggedPort ($ifaceList->$idx) -1] >=0) do={
                :set orderedUntaggedPort ($orderedUntaggedPort, ($ifaceList->$idx))
            }
            :set idx ($idx + 1)
        }
        :set idx 0
        :while (($idx < $lenIfaceList) and ([:len $orderedTaggedPort] < $lenTagged)) do={
            :if ([:find $taggedPort ($ifaceList->$idx) -1] >=0) do={
                :set orderedTaggedPort ($orderedTaggedPort, ($ifaceList->$idx))
            }
            :set idx ($idx + 1)
        }
        :put ("--- VLAN-ID(s) " . [$"_arrayToCommaSeperatedString" $vlanIDs] . " ---")
        if (([:len $untaggedPort] = [:len $orderedUntaggedPort]) and ([:len $taggedPort] = [:len $orderedTaggedPort])) do={
# We do only concider changing the configuration if the ordered lists are complete.
            if ($untaggedPort != $orderedUntaggedPort) do={
# Apparently a comparsion of arrays with the same content but in different order results in "not equal".
                $"_applyChange" $vlanIDs $orderedUntaggedPort "untagged" $1
                :set changeProposed yes
            }
            if ($taggedPort != $orderedTaggedPort) do={
                $"_applyChange" $vlanIDs $orderedTaggedPort "tagged" $1
                :set changeProposed yes
            }
        } else={
            :put ("ERROR: vlan-ids " . [$"_arrayToCommaSeperatedString" $vlanIDs] . " members do not EXCLUSIVELY consist of interface types ether or bridge.\r\n" \
                . "HINT:  Check the configuration with:\r\n/interface/bridge/vlan/print detail where vlan-ids=" \
                . [$"_arrayToCommaSeperatedString" $vlanIDs])
        }
        :put ""
    }
    :if ($changeProposed and [:typeof $1] = "nothing") do={
        :put ("If you are happy with the proposed changes you might run this script again and let it apply the proposed changes for you.\r\n" \
              . $0 . " doit") 
    }
}
