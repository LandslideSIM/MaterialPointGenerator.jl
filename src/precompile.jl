@setup_workload begin
    points = rand(20, 3)
    @compile_workload begin
        quiet() do
           #b = np.array(a)
        end
    end
end