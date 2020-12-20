## this is *sourced* from the main script so that it inherits the
## shell variables from that script

ipt64dscp(){
    iptables -t mangle -A dscptag $*
    ip6tables -t mangle -A dscptag $*
}
ipt4dscp() {
    iptables -t mangle -A dscptag $*
}
ipt6dscp() {
    ip6tables -t mangle -A dscptag $*
}


## downgrade torrents etc UDP:
ipt64dscp -p udp -m multiport --sports "$UDPBULKPT" -j DSCP --set-dscp-class CS1
ipt64dscp -p udp -m multiport --dports "$UDPBULKPT" -j DSCP --set-dscp-class CS1

## downgrade torrents etc TCP:
ipt64dscp -p tcp -m multiport --sports "$TCPBULKPT" -j DSCP --set-dscp-class CS1
ipt64dscp -p tcp -m multiport --dports "$TCPBULKPT" -j DSCP --set-dscp-class CS1


## boost jitsi meet udp to CS4, if you have the bandwidth you can
## boost these video conferences to CS5 and make it realtime, but then
## it can interfere with other realtime/game. Often CS4 will be enough

ipt64dscp -p udp --dport 10000 -j DSCP --set-dscp-class CS4
ipt64dscp -p udp --sport 10000 -j DSCP --set-dscp-class CS4

## boost zoom to CS4
ipt64dscp -p udp -m multiport --sports 3478:3479,8801:8802 -j DSCP --set-dscp-class CS4
ipt64dscp -p udp -m multiport --dports 3478:3479,8801:8802 -j DSCP --set-dscp-class CS4

## boost google meet CS4
ipt64dscp -p udp -m multiport --sports 19302:19309 -j DSCP --set-dscp-class CS4
ipt64dscp -p udp -m multiport --dports 19302:19309 -j DSCP --set-dscp-class CS4

## boost webex to CS4

ipt64dscp -p udp --dport 9000 -j DSCP --set-dscp-class CS4
ipt64dscp -p udp --sport 9000 -j DSCP --set-dscp-class CS4


## boost DNS traffic
ipt4dscp -p udp --dport 53 -j DSCP --set-dscp-class CS4
ipt4dscp -p udp --sport 53 -j DSCP --set-dscp-class CS4


## boost the gaming machines UDP always to CS5 for realtime access if
## you have a low total bandwidth so that game/total is definitely
## above say 0.2, you might prefer to set CS4 here and use a
## link-share class, which will have a bit more jitter, but may enable
## you to drain backlogs faster

ipt4dscp -p udp -m set --match-set "${GAMINGIPSET4}" src -j DSCP --set-dscp-class CS5
ipt4dscp -p udp -m set --match-set "${GAMINGIPSET4}" dst -j DSCP --set-dscp-class CS5

ipt6dscp -p udp -m set --match-set "${GAMINGIPSET6}" src -j DSCP --set-dscp-class CS5
ipt6dscp -p udp -m set --match-set "${GAMINGIPSET6}" dst -j DSCP --set-dscp-class CS5


## downgrade UDP tagged CS5 that sends more than 200 pps (seems
## unlikely to be gaming traffic, more likely QUIC), comment this out
## if you want, or change to CS1 to further down-priority

ipt4dscp -p udp -m dscp --dscp-class CS5 -m hashlimit --hashlimit-mode srcip,srcport,dstip,dstport --hashlimit-name udpbulk4 --hashlimit-above 200/second --hashlimit-burst 200 --hashlimit-rate-match --hashlimit-rate-interval 1 -j DSCP --set-dscp-class CS2

## some games use TCP, let's match on TCP streams using less than
## 150pps this probably is interactive rather than a bulk
## transfer.

ipt4dscp -p tcp -m set --match-set "${GAMINGIPSET4}" src  -m hashlimit --hashlimit-mode srcip,srcport,dstip,dstport --hashlimit-name tcphighprio4 --hashlimit-upto 150/second --hashlimit-burst 150 --hashlimit-rate-match --hashlimit-rate-interval 1 -j DSCP --set-dscp-class CS4

ipt4dscp -p tcp -m set --match-set "${GAMINGIPSET4}" dst  -m hashlimit --hashlimit-mode srcip,srcport,dstip,dstport --hashlimit-name tcphighprio4 --hashlimit-upto 150/second --hashlimit-burst 150 --hashlimit-rate-match --hashlimit-rate-interval 1 -j DSCP --set-dscp-class CS4

ipt6dscp -p tcp -m set --match-set "${GAMINGIPSET6}" src  -m hashlimit --hashlimit-mode srcip,srcport,dstip,dstport --hashlimit-name tcphighprio6 --hashlimit-upto 150/second --hashlimit-burst 150 --hashlimit-rate-match --hashlimit-rate-interval 1 -j DSCP --set-dscp-class CS4

ipt6dscp -p tcp -m set --match-set "${GAMINGIPSET6}" dst  -m hashlimit --hashlimit-mode srcip,srcport,dstip,dstport --hashlimit-name tcphighprio6 --hashlimit-upto 150/second --hashlimit-burst 150 --hashlimit-rate-match --hashlimit-rate-interval 1 -j DSCP --set-dscp-class CS4

