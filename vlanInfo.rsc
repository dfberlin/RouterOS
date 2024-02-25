global vlanInfo do={
# Expects the default-name of an interface as argument in $1.
    :local element
    :local arrayVIDs
    :local arrayTagged
    :local arrayUntagged
    :local memberTagged
    :local memberUntagged
    :local currentPVID
    :local currentFrameTypes
    :local currentBridge
#   :local currentIngressFiltering
# Transforming the default name to the currently given name. ether1 could turn into ether1-testport in case the interface has been renamed.
    :local currentInterfaceName [/interface/ethernet/get value-name=name number=[/interface/ethernet/find where default-name="$1"]]

    foreach element in=[/interface/bridge/vlan/find vlan-ids] do={
        :set arrayVIDs [/interface/bridge/vlan/get value-name=vlan-ids number=$element]
        :set arrayTagged [/interface/bridge/vlan/get value-name=tagged  number=$element]
        :set arrayUntagged [/interface/bridge/vlan/get value-name=untagged  number=$element]
# find returns either an array index >= 0 in case of a match or nil if no match has been found.
        :if ([:find $arrayTagged "$currentInterfaceName" -1] >= 0) do={
#           :put "Found it ;)"
            foreach id in=$arrayVIDs do={
                :set memberTagged ($memberTagged , $id)
            }
        }
        :if ([:find $arrayUntagged "$currentInterfaceName" -1] >= 0) do={
#           :put "Found it ;)"
            foreach id in=$arrayVIDs do={
                :set memberUntagged ($memberUntagged , $id)
            }
        }
    }
# Re-Using element since we already passed the loop.
    :set element [/interface/bridge/port/find where interface=$currentInterfaceName]
    :set currentPVID [/interface/bridge/port/get value-name=pvid number=$element]
    :set currentFrameTypes [/interface/bridge/port/get value-name=frame-types number=$element]
    :set currentBridge [/interface/bridge/port/get value-name=bridge number=$element]
#    :set currentIngressFiltering [/interface/bridge/port/get value-name=ingress-filtering number=$element]
    :put "----------------------------------------"
    :put ("bride:             " . $currentBridge)
    :put ("port:              " . $currentInterfaceName)
    :put ("pvid:              " . $currentPVID)
    :put ("frame-types:       " . $currentFrameTypes)
#    :put ("ingress-filtering: " . $currentIngressFiltering)
    :if ([:len $memberUntagged] > 0) do={
        :put ("untagged:          " . [:tostr $memberUntagged])
    }
    :if ([:len $memberTagged] > 0) do={
        :put ("tagged:            " . [:tostr $memberTagged])
    }
    :put "----------------------------------------"
}
