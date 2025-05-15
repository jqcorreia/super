#version 330 core

uniform vec2 resolution;
/*
    "Cosmic" by @XorDev

    I love making these glowy shaders. This time I thought I'd try using discs instead.

    Tweet: twitter.com/XorDev/status/1601060422819680256
    Twigl: t.co/IhRk3HX4Kt

    <300 chars playlist: shadertoy.com/playlist/fXlGDN
*/
uniform float iTime;

in vec3 fragCoord;

void mainImage(out vec4 O, vec2 I)
{
    //Clear fragcolor (hacky)
    O = vec4(0.0, 0.0, 0.0, 1.0); // Setting alpha to 1.0 so it doesn't get blended with the background

    //Initialize resolution for scaling
    vec2 r = resolution.xy,
    //Save centered pixel coordinates
    p = (I - r * .6) * mat2(1, -1, 2, 2);

    //Initialize loop iterator and arc angle
    for (float i = 0., a;
        //Loop 300 times
        i++ < 3e1;
        //Add with ring attenuation
        O += .2 / (abs(length(I = p / (r + r - p).y) * 8e1 - i) + 4e1 / r.y) *
                //Limit to arcs
                clamp(cos(a = atan(I.y, I.x) * ceil(i * .1) + iTime * sin(i * i) + i * i), .0, .6) *
                //Give them color
                (cos(a - i + vec4(0, 1, 2, 0)) + 1.));
}

void main() {
    mainImage(gl_FragColor, fragCoord.xy * resolution);
}
