
# Random Notes

Just a collection of notes to help the process.

## Transmitters

| Transmitter | Typical Frequency | Channel Bandwidth | Typical Power / EIRP | Waveform | Passive Radar Considerations |
|---|---|---|---|---|---|
| FM Radio | 88–108 MHz | ~100–200 kHz | ~10–100 kW EIRP | Analog FM | Strong coverage; poor range resolution |
| DAB / DAB+ | 174–240 MHz | 1.536 MHz | ~1–10 kW EIRP | OFDM | Stable illumination; modest bandwidth |
| DVB-T | ~470–700 MHz | 6, 7, or 8 MHz | ~1–100 kW EIRP | OFDM | Strong continuous broadcast signal |
| DVB-T2 | ~470–700 MHz | 6, 7, or 8 MHz | ~1–100 kW EIRP | OFDM | Good reference signal for drone detection |
| ATSC 1.0 | ~54–608 MHz (US) | 6 MHz | Station-dependent; can reach hundreds of kW ERP | 8-VSB | Common US television illuminator |
| ATSC 3.0 | ~54–608 MHz (US) | 6 MHz | Station-dependent; can reach hundreds of kW ERP | OFDM | Modern US broadcast option |
| LTE / 4G | ~600 MHz–3.7 GHz | 1.4–20 MHz | Macro radios often tens of W per RF port | OFDMA downlink | Cellular coverage; variable occupancy |
| 5G NR (FR1) | ~600 MHz–7.125 GHz | 5–100 MHz | Deployment-dependent | OFDM | Wide bandwidth; beamforming and TDD complexity |
| Wi-Fi | 2.4 / 5 / 6 GHz | 20–320 MHz | Usually mW-to-low-W EIRP | OFDM / OFDMA | High resolution; short-range and intermittent |
| Satellite LTE (Direct-to-Cell) | ~1.6–2.7 GHz (example) | Operator / deployment dependent | Satellite-beam-dependent | LTE-derived | Moving transmitter; Doppler compensation needed |
| Starlink Ku Downlink | 10.7–12.7 GHz | Variable; some configurations use 240 MHz channels | Satellite-beam-dependent | Proprietary broadband | High frequency; moving transmitter |

## Center Frequency? Bandwidth?

**Center frequency** is where the radio signal is located in the frequency spectrum.

**Bandwidth** is how wide that signal is. A 1.8 GHz signal with 10 MHz bandwidth means it spans from 1795 MHz to 1805 MHz.

### Significance?

The center frequency determines the wavelength of the radio wave.

$$
\lambda = \frac{c}{f_c}
$$

Where $c$ is the speed of light.

Wavelength influences how radio waves reflect off objects.

Bandwidth determines how precisely we can distinguish signals based on their arrival times. We compare the direct signal with the signal reflected from an object.

The monostatic-equivalent range resolution is:

$$
\Delta R = \frac{c}{2B}
$$

### What About Micro-Doppler?

The Doppler frequency resolution is:

$$
\Delta f_D \approx \frac{1}{T_{\text{CPI}}}
$$

Where $T_{\text{CPI}}$ is the coherent processing interval (CPI), which determines how finely we can distinguish Doppler frequencies.
