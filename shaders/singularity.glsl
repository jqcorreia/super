#version 330 core

uniform vec2 resolution;
uniform float iTime;

in vec3 vPos;

void mainImage(out vec4 O, vec2 F)
{
    //Iterator and attenuation (distance-squared)
    float i = .2, a;
    //Resolution for scaling and centering
    vec2 r = resolution.xy,
    //Centered ratio-corrected coordinates
    p = (F + F - r) / r.y / .7,
    //Diagonal vector for skewing
    d = vec2(-1, 1),
    //Blackhole center
    b = p - i * d,
    //Rotate and apply perspective
    c = p * mat2(1, 1, d / (.1 + i / dot(b, b))),
    //Rotate into spiraling coordinates
    v = c * mat2(cos(.5 * log(a = dot(c, c)) + iTime * i + vec4(0, 33, 11, 0))) / i,
    //Waves cumulative total for coloring
    w;

    //Loop through waves
    for (; i++ < 9.; w += 1. + sin(v))
        //Distort coordinates
        v += .7 * sin(v.yx * i + iTime) / i + .5;
    //Acretion disk radius
    i = length(sin(v / .3) * .4 + c * (3. + d));
    //Red/blue gradient
    O = 1. - exp(-exp(c.x * vec4(.6, -.4, -1, 0))
                    //Wave coloring
                    / w.xyyx
                    //Acretion disk brightness
                    / (2. + i * i / 4. - i)
                    //Center darkness
                    / (.5 + 1. / a)
                    //Rim highlight
                    / (.03 + abs(length(p) - .7))
            );
    O = vec4(O.x, O.y, O.z, 1.0);
}

void main() {
    mainImage(gl_FragColor, vPos.xy * resolution);
}
