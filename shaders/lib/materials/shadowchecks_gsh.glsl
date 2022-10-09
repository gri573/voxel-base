switch (matV[0]) {
    case 10064:
        if (dot(cnormal, vec3(0, 1, 0)) < 0.95) tracemat = false;
        else avgPos -= 0.05 * cnormal;
        break;
    case 31000:
        zpos = 0.3 * zpos + 0.7;
    case 10068:
        if (area < 0.8) tracemat = false;
        break;
    case 10072:
    case 10076:
    case 12112:
        vec3 tempPos = fract(avgPos - 0.5);
        if (max(tempPos.x, max(tempPos.y, tempPos.z)) > 0.49) tracemat = false;
        break;
    case 10350:
        if (cnormal.y < 0.5) tracemat = false;
        avgPos.y -= 0.1;
        break;
    case 10548:
        if(area < 0.8) tracemat = false;
        break;
    case 10496:
    case 10528:
    case 10604:
    case 12604:
        if (cnormal.y < 0.5) tracemat = false;
        //avgPos += vec3(0.0, 0.1, 0.0);
        break;
    case 10544:
    case 10596:
    case 10600:
        avgPos += 0.1 * cnormal;
        break;
    case 0:
    case 10472:
    case 50016:
    case 50996:
    case 60004:
        tracemat = false;
        break;
    default:
        avgPos -= 0.05 * cnormal;
        break;
}