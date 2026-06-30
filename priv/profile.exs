# Profile IdenticonSvg.generate/6 at various sizes and configurations
#
# Usage: mix run priv/profile.exs

inputs = [
  {"size=4, transparent",        fn -> IdenticonSvg.generate("hello", 4) end},
  {"size=5, transparent",        fn -> IdenticonSvg.generate("hello", 5) end},
  {"size=7, transparent",        fn -> IdenticonSvg.generate("hello", 7) end},
  {"size=10, transparent",       fn -> IdenticonSvg.generate("hello", 10) end},
  {"size=5, basic bg",           fn -> IdenticonSvg.generate("hello", 5, :basic) end},
  {"size=5, hex bg #f00",        fn -> IdenticonSvg.generate("hello", 5, "#f00") end},
  {"size=5, padding=2",          fn -> IdenticonSvg.generate("hello", 5, nil, 1.0, 2) end},
  {"size=5, squircle curv=0.8",  fn -> IdenticonSvg.generate("hello", 5, nil, 1.0, 0, squircle_curvature: 0.8) end},
  {"size=10, full opts",         fn -> IdenticonSvg.generate("hello", 10, :split2, 0.7, 3, squircle_curvature: 0.9) end},
]

iterations = 200

IO.puts("Profiling IdenticonSvg.generate/6 — #{iterations} iterations each\n")
IO.puts(String.pad_trailing("Scenario", 42) <> "avg μs    min μs    max μs")

Enum.each(inputs, fn {label, fun} ->
  for _ <- 1..20, do: fun.()  # warmup

  times =
    for _ <- 1..iterations do
      {time, _result} = :timer.tc(fun)
      time
    end

  avg = round(Enum.sum(times) / length(times))
  min = Enum.min(times)
  max = Enum.max(times)

  IO.puts(String.pad_trailing(label, 42) <>
          String.pad_leading("#{avg}", 8) <>
          String.pad_leading("#{min}", 10) <>
          String.pad_leading("#{max}", 10))
end)

IO.puts("\n--- SVG output size ---")
IO.puts("size=4:         #{byte_size(IdenticonSvg.generate("hello", 4))} bytes")
IO.puts("size=5:         #{byte_size(IdenticonSvg.generate("hello", 5))} bytes")
IO.puts("size=10:        #{byte_size(IdenticonSvg.generate("hello", 10))} bytes")
IO.puts("size=5+bg:      #{byte_size(IdenticonSvg.generate("hello", 5, :basic))} bytes")
IO.puts("size=5+squircle:#{byte_size(IdenticonSvg.generate("hello", 5, nil, 1.0, 0, squircle_curvature: 0.8))} bytes")
