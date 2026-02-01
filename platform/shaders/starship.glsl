#version 330 core

uniform vec2 resolution;
uniform float iTime;
uniform sampler2D iChannel0;

in vec3 fragCoord;

void mainImage(out vec4 O, vec2 I)
{
    //Resolution for scaling
    vec2 r = resolution.xy,
    //Center, rotate and scale
    p = (I + I - r) / r.y * mat2(3, 4, 4, -3) / 1e2;

    //Sum of colors, RGB color shift and wave
    vec4 S, C = vec4(1, 2, 3, 0), W;

    //Time, trailing time and iterator variables
    //Iterate through 50 particles
    for (float t = iTime, T = .1 * t + p.y, i; i++ < 50.;

        ///Set color:
        //The sine gives us color index between -1 and +1.
        //Then we give each channel a separate frequency.
        //Red is the broadest, while blue dissipates quickly.
        //Add one to avoid negative color values (0 to 2).
        S += (cos(W = sin(i) * C) + 1.)

                ///Flashing brightness:
                //The brightness fluxuates exponentially between 1/e and e.
                //Each particle has a flash frequency according to its index.
                * exp(sin(i + i * T))

                ///Trail particles with attenuating light:
                //The basic idea is to start with a point light falloff.
                //I used max on the coordinates so that I can scale the
                //positive and negative directions independently.
                //The x axis is scaled down a lot for a long trail.
                //Noise is added to the scaling factor for cloudy depth.
                //The y-axis is also stretched a little for a glare effect.
                //Try a higher value like 4 for more clarity
                / length(max(p,
                        p / vec2(2, texture(iChannel0, p / exp(W.x) + vec2(i, t) / 8.) * 40.))
                ) / 1e4)

        ///Shift position for each particle:
        //Frequencies to distribute particles x and y independently
        //i*i is a quick way to hide the sine wave periods
        //t to shift with time and p.x for leaving trails as it moves
        p += .02 * cos(i * (C.xz + 8. + i) + T + T);

    //Add sky background and "tanh" tonemap
    O = tanh(p.x * --C + S * S);
}

void main() {
    mainImage(gl_FragColor, fragCoord.xy * resolution);
}
