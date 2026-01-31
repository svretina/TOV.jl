# Theory

## The TOV Equations

The structure of a static, spherically symmetric relativistic star is governed by the Tolman-Oppenheimer-Volkoff equations:

```math
\begin{aligned}
\frac{dP}{dr} &= -(\epsilon + P) \frac{m + 4\pi r^3 P}{r(r - 2m)} \\
\frac{dm}{dr} &= 4\pi r^2 \epsilon \\
\frac{d\nu}{dr} &= -\frac{1}{\epsilon + P} \frac{dP}{dr}
\end{aligned}
```

where:
- $P(r)$ is the pressure,
- $\epsilon(r)$ is the total energy density,
- $m(r)$ is the enclosed gravitational mass,
- $\nu(r)$ is the metric potential defined by $g_{tt} = -e^{2\nu}$.

## Metric Matching

At the stellar surface ($R$), the interior metric must match the exterior Schwarzschild metric:
```math
e^{2\nu(R)} = 1 - \frac{2M}{R}
```
Our solver automatically shifts the interior potential $\nu(r)$ to ensure this condition is met.

## Baryonic Mass

The total baryonic mass $M_b$ (rest mass) is calculated by integrating the proper volume element weighted by the rest-mass density $\rho_0$:
```math
\frac{dM_b}{dr} = \frac{4\pi r^2 \rho_0}{\sqrt{1 - 2m/r}}
```
This quantity is conserved during evolution and is critical for binding energy calculations ($E_b = M_b - M$).
