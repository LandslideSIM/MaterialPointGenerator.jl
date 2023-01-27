# test file for utils.jl
a = [1.2 2.3 5.0; 3.4 4.5 6.0; 5.6 6.7 7.0]
savexyz(joinpath(testassets, "testutils.xyz"), a)
b = readxyz(joinpath(testassets, "testutils.xyz"))
@test b ≈ a
rm(joinpath(testassets, "testutils.xyz"))