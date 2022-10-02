switch (matV[0]) {
    case 10064:
        if (dot(cnormal, vec3(0, 1, 0)) < 0.95) tracemat = false;
        else avgPos -= 0.05 * cnormal;
        break;
    case 31000:
    case 10068:
        if (area < 0.8) tracemat = false;
        break;
    case 10072:
    case 10076:
    case 12112:
        vec3 tempPos = fract(avgPos - 0.5);
        if (max(tempPos.x, max(tempPos.y, tempPos.z)) > 0.49) tracemat = false;
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
    case 50016:
        tracemat = false;
        break;
    default:
        avgPos -= 0.05 * cnormal;
        break;
}