// needs bool emissive, alphatest, crossmodel, cuboid, full, entity; vec3 lightcol; ivec3[2] bounds (in 1/16 blocks); int mat

//entities
entity = (mat / 10000 == 5);
//exclude from ray tracing
notrace = (
    entity ||
    mat == 10072 ||
    mat == 10076 ||
    mat == 10012 ||
    mat == 10083 ||
    mat == 12152 ||
    mat == 12156 ||
    mat == 12164 ||
    mat == 12172 ||
    mat == 12180 ||
    mat == 12188 ||
    mat == 12196 ||
    mat == 12204 ||
    mat == 12212 ||
    mat == 12220 ||
    mat == 12264 ||
    mat == 12312 ||
    mat == 12480 ||
    (mat >= 10596 && mat <= 10600) ||
    mat == 10544 ||
    mat == 12696 ||
    mat == 10732
);
//translucent / alpha cutout blocks:
alphatest = (
    mat == 10000 ||
    mat == 10004 ||
    mat == 10008 ||
    mat == 10016 ||
    mat == 10020 ||
    mat == 10041 ||
    mat == 10072 ||
    mat == 10076 ||
    mat == 12112 ||
    mat == 10448 ||
    mat == 10544 ||
    mat == 10596 ||
    mat == 10600 ||
    mat == 10708 ||
    (mat >= 10720 && mat < 10724) ||
    (mat / 10000 == 3 && mat != 31016)
);
//light sources
emissive = (
    mat == 10056 ||
    mat == 10068 ||
    mat == 10072 ||
    mat == 10076 ||
    mat == 10216 ||
    mat == 10224 ||
#ifdef EMISSIVE_ORES
    mat == 10272 ||
    mat == 10276 ||
    mat == 10284 ||
    mat == 10288 ||
    mat == 10300 ||
    mat == 10304 ||
    mat == 10320 ||
    mat == 10340 ||
    mat == 10344 ||
    mat == 10612 ||
    mat == 10616 ||
    mat == 10620 ||
    mat == 10624 ||
#endif
//    mat == 10328 ||
    mat == 10332 ||
    mat == 10356 ||
    mat == 10388 ||
    mat == 10396 ||
    mat == 10400 ||
    mat == 10401 ||
    mat == 10412 ||
    mat == 10448 ||
    mat == 10452 ||
    mat == 10458 ||
    mat == 10476 ||
    mat == 10496 ||
    mat == 10500 ||
    mat == 10501 ||
    mat == 10502 ||
    mat == 10508 ||
    mat == 10516 ||
    mat == 10528 ||
    mat == 10544 ||
    mat == 10548 ||
    mat == 10556 ||
    mat == 10560 ||
    mat == 10564 ||
    (mat >= 10572 && mat < 10588) ||
    mat == 10592 ||
    (mat >= 10596 && mat < 10600) ||
    mat == 12604 ||
    mat == 10612 ||
    mat == 10616 ||
    mat == 10620 ||
    mat == 10624 ||
    mat == 10632 ||
    mat == 10640 ||
    (mat >= 10648 && mat < 10660) ||
    mat == 10680 ||
    mat == 10684 ||
    mat == 10688 ||
    mat == 10704 ||
    mat == 10708 ||
    mat == 10739 ||
    mat == 12740 ||
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
if (emissive) {
    switch (mat) {
        case 10056:
        case 10068:
        case 10072:
        case 10076:
        case 10396:
        case 10401:
        case 10412:
        case 10448:
        case 10452:
        case 10496:
        case 10500:
        case 10528:
        case 10640:
        case 10648:
        case 10652:
        case 10656:
            lightlevel = 20;
            break;
        case 12604:
            lightlevel = 20;
            lightcol = vec3(1.0, 0.1, 0.05);
            break;
        case 12740:
            lightlevel = 15;
            lightcol = vec3(1.0, 0.7, 0.4);
            break;
        case 10548:
            lightlevel = 15;
            lightcol = vec3(0.3, 0.5, 1.0);
            break;
        case 10739:
            lightlevel = 17;
            lightcol = vec3(1.0, 0.65, 0.05);
            break;
        case 10508:
            lightlevel = 16;
            lightcol = vec3(1.0, 0.7, 0.9);
            break;
        case 10560:
            lightlevel = 20;
            lightcol = vec3(1.0, 0.8, 0.5);
            break;
        case 10564:
            lightlevel = 20;
            lightcol = vec3(0.5, 0.95, 1.0);
            break;
        case 10596:
            lightlevel = 6;
            lightcol = vec3(1.0, 0.1, 0.05);
            break;
        case 10597:
            lightlevel = 7;
            lightcol = vec3(1.0, 0.1, 0.05);
            break;
        case 10598:
            lightlevel = 8;
            lightcol = vec3(1.0, 0.1, 0.05);
            break;
        case 10599:
            lightlevel = 9;
            lightcol = vec3(1.0, 0.1, 0.05);
            break;
        case 30020:
        case 10400:
        case 10584:
        case 10616:
        case 10624:
        case 10704:
            lightlevel = 15;
            break;
        default:
            lightlevel = 13;
            break;
    }
}
//full cubes
full = (
    mat == 10008 ||
    mat == 10028 ||
    mat == 10032 ||
    mat == 10080 ||
    mat == 10084 ||
    mat == 10088 ||
    mat == 10092 ||
    mat == 10096 ||
    mat == 10100 ||
    mat == 10104 ||
    mat == 10108 ||
    mat == 10112 ||
    mat == 12112 ||
    mat == 10116 ||
    mat == 10120 ||
    mat == 10124 ||
    mat == 10128 ||
    mat == 10132 ||
    mat == 10140 ||
    mat == 10144 ||
    mat == 10148 ||
    mat == 10152 ||
    mat == 10156 ||
    mat == 10160 ||
    mat == 10164 ||
    mat == 10168 ||
    mat == 10172 ||
    mat == 10176 ||
    mat == 10180 ||
    mat == 10184 ||
    mat == 10188 ||
    mat == 10192 ||
    mat == 10196 ||
    mat == 10200 ||
    mat == 10204 ||
    mat == 10208 ||
    mat == 10212 ||
    mat == 10216 ||
    mat == 10220 ||
    (mat > 10223 && mat < 10240) ||
    mat == 10240 ||
    mat == 10244 ||
    mat == 10248 ||
    mat == 10252 ||
    mat == 10264 ||
    (mat > 10267 && mat < 10292) ||
    mat == 10292 ||
    (mat > 10295 && mat < 10312) ||
    (mat > 10315 && mat < 10332) ||
    mat == 10336 ||
    mat == 10340 ||
    mat == 10344 ||
    mat == 10352 ||
    mat == 10356 ||
    mat == 10360 ||
    mat == 10364 ||
    mat == 10368 ||
    mat == 10372 ||
    mat == 10376 ||
    mat == 10380 ||
    mat == 10384 ||
    mat == 10388 ||
    mat == 10392 ||
    mat == 10396 ||
    mat == 10404 ||
    mat == 10408 ||
    mat == 10412 ||
    mat == 10416 ||
    mat == 10420 ||
    mat == 10424 ||
    mat == 10428 ||
    mat == 10432 ||
    mat == 10436 ||
    mat == 10440 ||
    mat == 10444 ||
    mat == 10448 ||
    mat == 10452 ||
    mat == 10456 ||
    mat == 10460 ||
    mat == 10464 ||
    mat == 10468 ||
    mat == 10476 ||
    mat == 10480 ||
    mat == 10484 ||
    mat == 10516 ||
    mat == 10524 ||
    mat == 10532 ||
    mat == 10536 ||
    mat == 10540 ||
    mat == 10576 ||
    mat == 10580 ||
    mat == 10588 ||
    mat == 10592 ||
    (mat > 10607 && mat < 10628) ||
    mat == 10636 ||
    mat == 10640 ||
    mat == 10648 ||
    mat == 10664 ||
    mat == 10668 ||
    (mat >= 10672 && mat < 10697) ||
    mat == 10700 ||
    mat == 10708 ||
    mat == 10712 ||
    mat == 10716 ||
    mat == 10724 ||
    mat == 30000 ||
    mat == 30008 ||
    mat == 30012 ||
    mat == 30016 ||
    mat == 31004 ||
    mat == 31008 ||
    mat == 60000 ||
    mat == 60016
);
crossmodel = (
    mat == 10000 ||
    mat == 10004 ||
    mat == 10016 ||
    mat == 10020 ||
    mat == 10072 ||
    mat == 10076 ||
    mat == 10123 ||
    mat == 10332 ||
    mat == 10492
);
cuboid = (
    (mat > 10032 && mat < 10036) ||
    mat == 10041 ||
    mat == 10060 ||
    mat == 10064 ||
    mat == 10068 ||
    (mat > 10080 && mat < 10084) ||
    (mat > 10084 && mat < 10088) ||
    (mat > 10088 && mat < 10092) ||
    (mat > 10092 && mat < 10096) ||
    (mat > 10096 && mat < 10100) ||
    (mat > 10100 && mat < 10104) ||
    (mat > 10104 && mat < 10108) ||
    (mat > 10108 && mat < 10112) ||
    (mat > 10112 && mat < 10116) ||
    mat == 10121 ||
    mat == 10129 ||
    mat == 10137 ||
    (mat > 10152 && mat < 10156) ||
    mat == 12153 ||
    (mat > 10156 || mat < 10160) ||
    mat == 12157 ||
    (mat >= 14156 && mat < 14160) ||
    (mat > 10164 || mat < 10168) ||
    mat == 12165 ||
    (mat >= 14164 && mat < 14168) ||
    (mat > 10172 || mat < 10176) ||
    mat == 12173 ||
    (mat >= 14172 && mat < 14176) ||
    (mat > 10180 || mat < 10184) ||
    mat == 12181 ||
    (mat >= 14180 && mat < 14184) ||
    (mat > 10188 || mat < 10192) ||
    mat == 12189 ||
    (mat >= 14188 && mat < 14192) ||
    (mat > 10196 || mat < 10200) ||
    mat == 12197 ||
    (mat >= 14196 && mat < 14200) ||
    (mat > 10204 || mat < 10208) ||
    mat == 12205 ||
    (mat >= 14204 && mat < 14208) ||
    (mat > 10212 || mat < 10216) ||
    mat == 12213 ||
    (mat >= 14212 && mat < 14216) ||
    (mat > 10220 || mat < 10224) ||
    mat == 12221 ||
    (mat > 14220 && mat < 14224) ||
    (mat > 10240 || mat < 10244) ||
    (mat > 10244 || mat < 10248) ||
    mat == 10256 ||
    (mat >= 14260 && mat < 14264) ||
    mat == 10265 ||
    mat == 12265 ||
    (mat >= 14264 && mat < 14268) ||
    (mat > 10292 && mat < 10296) ||
    (mat >= 12292 && mat < 12296) ||
    mat == 10313 ||
    mat == 10350 ||
    (mat > 10364 && mat < 10368) ||
    (mat > 10376 && mat < 10380) ||
    mat == 10381 ||
    mat == 10400 ||
    mat == 10401 ||
    mat == 10402 ||
    mat == 10403 ||
    (mat > 10416 && mat < 10420) ||
    (mat > 10420 && mat < 10424) ||
    (mat > 10428 && mat < 10432) ||
    (mat > 10440 && mat < 10444) ||
    (mat > 10444 && mat < 10448) ||
    (mat > 10480 && mat < 10484) ||
    mat == 10488 ||
    mat == 10496 ||
    mat == 10500 ||
    mat == 10501 ||
    mat == 10502 ||
    mat == 10504 ||
    mat == 10508 ||
    mat == 10512 ||
    mat == 10520 ||
    mat == 10528 ||
    mat == 10548 ||
    mat == 10552 ||
    mat == 10556 ||
    mat == 10560 ||
    mat == 10564 ||
    (mat > 10564 && mat < 10568) ||
    mat == 10568 ||
    mat == 10569 ||
    mat == 10584 ||
    mat == 11584 ||
    mat == 10596 ||
    mat == 10600 ||
    mat == 10604 ||
    mat == 12604 ||
    mat == 10644 ||
    mat == 10656 ||
    mat == 10660 ||
    mat == 10669 ||
    mat == 10697 ||
    mat == 10705 ||
    (mat >= 10720 && mat < 10724) ||
    mat == 10728 ||
    (mat >= 10740 && mat < 10749) ||
    mat == 31000 ||
    mat == 31016 ||
    mat == 60008 ||
    mat == 60012 ||
    mat == 60017 
);
if (cuboid) {
    switch (mat) {
        case 10041:
        case 10596:
        case 10600:
            bounds[1].y = 2;
            break;
        case 10060:
            bounds[0] = ivec3(7, 0, 7);
            bounds[1] = ivec3(9, 16, 9);
            break;
        case 10064:
            bounds[0] = ivec3(4, 0, 4);
            bounds[1] = ivec3(12, 14, 12);
            break;
        case 10068:
        case 10548:
        case 10552:
        case 10556:
        case 31000:
            bounds[1].y = int(16*fract(pos.y + 0.03125));
            break;
        case 10256:
            bounds[0] = ivec3(7, 0, 7);
            bounds[1] = ivec3(9, 16, 9);
            break;
        case 10313:
            bounds[0] = ivec3(5, 3, 5);
            bounds[1] = ivec3(11, 13, 11);
            break;
        case 10400:
        case 10402:
        case 10568:
            bounds[0] = ivec3(6, 0, 6);
            bounds[1] = ivec3(10, 6, 10);
            break;
        case 10401:
        case 10403:
        case 10569:
            bounds[0] = ivec3(3, 0, 3);
            bounds[1] = ivec3(13, 6, 13);
            break;
        case 10488:
            bounds[0] = ivec3(3, 0, 3);
            bounds[1] = ivec3(13, 1, 13);
            break;
        case 10500:
        case 12292:
            bounds[0].xz = ivec2(7);
            bounds[1].xz = ivec2(9);
            break;
        case 10501:
        case 12293:
            bounds[0].yz = ivec2(7);
            bounds[1].yz = ivec2(9);
            break;
        case 10502:
        case 12294:
            bounds[0].xy = ivec2(7);
            bounds[1].xy = ivec2(9);
            break;
        case 10504:
            bounds[0] = ivec3(4);
            bounds[1] = ivec3(12);
            break;
        case 10508:
        case 10512:
            bounds[0] = ivec3(1);
            bounds[1] = ivec3(15);
            break;
        case 10520:
            bounds[0].xz = ivec2(1);
            bounds[1].xz = ivec2(15);
            break;
        case 10560:
        case 10564:
            bounds[0] = ivec3(5, 1, 5);
            bounds[1] = ivec3(11, 7, 11);
            break;
        case 10565:
            bounds[0].yz = ivec2(7);
            bounds[1].yz = ivec2(9);
            break;
        case 10566:
            bounds[0].xz = ivec2(7);
            bounds[1].xz = ivec2(9);
            break;
        case 10567:
            bounds[0].xy = ivec2(7);
            bounds[1].xy = ivec2(9);
            break;
        case 10656:
        case 10660:
            bounds[1].y = 8;
            break;
        case 10584:
        case 11584:
            bounds[0] = ivec3(6, 0, 6);
            bounds[1] = ivec3(10, 6, 10);
            break;
        case 10496:
        case 10528:
        case 10604:
        case 12604:
            bounds[0] = ivec3(7, 0, 7);
            bounds[1] = ivec3(9, 10, 9);
            break;
        case 10644:
            bounds[1].y = 3;
            break;
        case 12153:
        case 10669:
            bounds[1].y = 1;
            break;
        case 10720:
            bounds[0].z = 12;
            break;
        case 10721:
            bounds[1].z = 4;
            break;
        case 10722:
            bounds[1].x = 4;
            break;
        case 10723:
            bounds[0].x = 12;
            break;
        case 10728:
            bounds[0] = ivec3(5, 0, 5);
            bounds[1] = ivec3(11, 6, 11);
            break;
        case 10740:
        case 12740:
            bounds[0] = ivec3(1, 0, 1);
            bounds[1] = ivec3(15, 8, 15);
            break;
        case 10741:
            bounds[0] = ivec3(3, 0, 1);
            bounds[1] = ivec3(15, 8, 15);
            break;
        case 10742:
            bounds[0] = ivec3(5, 0, 1);
            bounds[1] = ivec3(15, 8, 15);
            break;
        case 10743:
            bounds[0] = ivec3(7, 0, 1);
            bounds[1] = ivec3(15, 8, 15);
            break;
        case 10744:
            bounds[0] = ivec3(9, 0, 1);
            bounds[1] = ivec3(15, 8, 15);
            break;
        case 10745:
            bounds[0] = ivec3(11, 0, 1);
            bounds[1] = ivec3(15, 8, 15);
            break;
        case 10746:
            bounds[0] = ivec3(13, 0, 1);
            bounds[1] = ivec3(15, 8, 15);
            break;
        case 31016:
            bounds[0] = ivec3(2, 0, 2);
            bounds[1] = ivec3(14, 14, 14);
            break;
        case 60008:
        case 60012:
            bounds[0] = ivec3(1, 0, 1);
            bounds[1] = ivec3(15, 14, 15);
            break;
        case 61017:
            bounds[0].y = 3;
            bounds[1].y = 9;
            break;
        default:
            if ((mat % 10000) / 2000 == 0) {
                switch (mat % 4) {
                    case 1:
                        bounds[1].y = int(16*fract(pos.y + 0.03125));
                        break;
                    case 2:
                        bounds[0].y = 8;
                        break;
                    case 3:
                        bounds[0].xz = ivec2(6);
                        bounds[1].xz = ivec2(10);
                        break;
                }
            } else if ((mat % 10000) / 2000 == 1) {
                if (mat % 4 == 1) bounds[1].y = 13;
            } else if ((mat % 10000) / 2000 == 2) {
                switch(mat % 4) {
                    case 0:
                        bounds[0].z = 13;
                        break;
                    case 1:
                        bounds[1].z = 3;
                        break;
                    case 2:
                        bounds[1].x = 3;
                        break;
                    case 3:
                        bounds[0].x = 13;
                        break;
                }
            }
    }
}