using Distributions
using CSV
using DataFrames

dye1 = Normal(450, 30)
dye1_max = pdf(dye1, 450)
dye2 = Normal(600, 60)
dye2_max = pdf(dye2, 600)
dye3 = Normal(700, 10)
dye3_max = pdf(dye3, 700)

dye1_spectrum = map(x -> pdf(dye1,x)/dye1_max, 300:999)
dye2_spectrum = map(x -> pdf(dye2,x)/dye2_max, 300:999)
dye3_spectrum = map(x -> pdf(dye3,x)/dye3_max, 300:999)

dye1_spectrum[dye1_spectrum.<0.001] = 0
dye2_spectrum[dye2_spectrum.<0.001] = 0
dye3_spectrum[dye3_spectrum.<0.001] = 0
dye1_spectrum[dye1_spectrum.>100] = 100
dye2_spectrum[dye2_spectrum.>100] = 100
dye3_spectrum[dye3_spectrum.>100] = 100

df = DataFrame(
    Wavelength=collect(300:999),
    dye1=dye1_spectrum*100,
    dye2=dye2_spectrum*100,
    dye3=dye3_spectrum*100)

CSV.write("test_dyes_emission.csv", df)


dye1 = Normal(330, 100)
dye1_max = pdf(dye1, 330)
dye2 = Normal(480, 230)
dye2_max = pdf(dye2, 400)
dye3 = Normal(400, 140)
dye3_max = pdf(dye3, 380)

dye1_spectrum = map(x -> pdf(dye1,x)/dye1_max, 300:999)
dye2_spectrum = map(x -> pdf(dye2,x)/dye2_max, 300:999)
dye3_spectrum = map(x -> pdf(dye3,x)/dye3_max, 300:999)

dye1_spectrum[dye1_spectrum.<0.001] = 0
dye2_spectrum[dye2_spectrum.<0.001] = 0
dye3_spectrum[dye3_spectrum.<0.001] = 0
dye1_spectrum[dye1_spectrum.>100] = 100
dye2_spectrum[dye2_spectrum.>100] = 100
dye3_spectrum[dye3_spectrum.>100] = 100

df = DataFrame(
    Wavelength=collect(300:999),
    dye1=dye1_spectrum*100,
    dye2=dye2_spectrum*100,
    dye3=dye3_spectrum*100)

CSV.write("test_dyes_excitation.csv", df)
