// needs bool emissive, alphatest, crossmodel, cuboid, full, entity; vec3 lightcol; ivec3[2] bounds (in 1/16 blocks); int mat

//entities
entity = (mat / 10000 == 5);
//exclude from ray tracing
notrace = (
    entity ||
    mat == 10072 ||
    mat == 10076
);
//translucent / alpha cutout blocks:
alphatest = (
    (mat > 9999 && mat < 10021) ||
    mat == 10040 ||
    mat == 10072 ||
    mat == 10076 ||
    mat == 10448 ||
    mat == 10544 ||
    mat == 10596 ||
    mat == 10600 ||
    mat == 10708 ||
    (mat / 10000 == 3 && mat != 31016)
);
//light sources
emissive = (
    mat == 10056 ||
    mat == 10068 ||
    mat == 10072 ||
    mat == 10076 ||
    mat == 10320 ||
    mat == 10356 ||
    mat == 10388 ||
    mat == 10396 ||
    mat == 10400 ||
    mat == 10412 ||
    mat == 10448 ||
    mat == 10458 ||
    mat == 10476 ||
    mat == 10496 ||
    mat == 10500 ||
    mat == 10516 ||
    mat == 10528 ||
    mat == 10544 ||
    mat == 10548 ||
    mat == 10556 ||
    mat == 10560 ||
    mat == 10564 ||
    (mat > 10571 && mat < 10588) ||
    mat == 10592 ||
    mat == 10596 ||
    (mat > 10603 && mat < 10628) ||
    mat == 10632 ||
    mat == 10640 ||
    (mat > 10647 && mat < 10660) ||
    mat == 10680 ||
    mat == 10684 ||
    mat == 10688 ||
    mat == 10708 ||
    mat == 30020 ||
    mat == 31016 ||
    mat == 60000 ||
    mat == 60012 ||
    mat == 60020 ||
    mat == 50000 ||
    mat == 50004 ||
    mat == 50012 ||
    mat == 50020 ||
    mat == 50048 ||
    mat == 50080
);
//full cubes
full = (
    mat == 10008 ||
    mat == 10028 ||
    mat == 10080 ||
    mat == 10116 ||
    mat == 10124 ||
    mat == 10132 ||
    mat == 10140 ||
    mat == 10144 ||
    mat == 10148 ||
    mat == 10160 ||
    mat == 10168 ||
    mat == 10176 ||
    mat == 10184 ||
    mat == 10192 ||
    mat == 10200 ||
    mat == 10208 ||
    mat == 10216 ||
    (mat > 10223 && mat < 10240) ||
    mat == 10248 ||
    mat == 10252 ||
    (mat > 10267 && mat < 10292) ||
    (mat > 10295 && mat < 10312) ||
    (mat > 10315 && mat < 10332) ||
    mat == 10336 ||
    mat == 10240 ||
    mat == 10344 ||
    mat == 10352 ||
    mat == 10356 ||
    mat == 10360 ||
    mat == 10368 ||
    mat == 10372 ||
    mat == 10384 ||
    mat == 10388 ||
    mat == 10392 ||
    mat == 10396 ||
    mat == 10404 ||
    mat == 10408 ||
    mat == 10412 ||
    mat == 10424 ||
    mat == 10432 ||
    mat == 10436 ||
    mat == 10448 ||
    mat == 10452 ||
    mat == 10456 ||
    mat == 10460 ||
    mat == 10464 ||
    mat == 10468 ||
    mat == 10476 ||
    mat == 10484 ||
    mat == 10516 ||
    mat == 10524 ||
    mat == 10532 ||
    mat == 10536 ||
    mat == 10576 ||
    mat == 10580 ||
    mat == 10588 ||
    mat == 10592 ||
    (mat > 10607 && mat < 10628) ||
    mat == 10636 ||
    mat == 10640 ||
    mat == 10648 ||
    mat == 10664 ||
    (mat > 10671 && mat < 10692) ||
    mat == 10708 ||
    mat == 10712 ||
    mat == 10716 ||
    mat == 10724 ||
    mat == 30000 ||
    mat == 30008 ||
    mat == 30012 ||
    mat == 30016 ||
    mat == 31004 ||
    mat == 31008
);
crossmodel = (
    mat == 10004 ||
    mat == 10072 ||
    mat == 10076 ||
    mat == 10060 ||
    mat == 10332 ||
    mat == 10492
);
cuboid = (
    mat == 10056 ||
    mat == 10656 ||
    mat == 10660 ||
    mat == 31000
);
if (cuboid) {
    switch (mat) {
        case 10068:
        case 31000:
            bounds[1].y = int(16*fract(pos.y));
            break;
        case 10656:
        case 10660:
            bounds[1].y = 9;
            break;
    }
}
if (emissive) {
    switch (mat) {
        case 10056:
        case 10068:
        case 10072:
        case 10076:
        case 10396:
        case 10412:
        case 10448:
        case 10652:
        case 10656:
            lightlevel = 20;
            break;
        case 10496:
        case 10528:
        case 10604:
            lightlevel = 15;
            break;
        default:
            lightlevel = 10;
            break;
    }
}