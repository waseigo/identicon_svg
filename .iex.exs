IEx.configure(inspect: [charlists: :as_lists])
alias IdenticonSvg.{Identicon, EdgeCleaner, EdgeTracer, Pathfinder, PolygonReducer, Color, Draw, Sunday}

connected = [ [{0, 10}, {1, 10}], [{1, 10}, {2, 10}], [{2, 10}, {3, 10}], [{3, 10}, {4, 10}], [{4, 10}, {5, 10}], [{5, 10}, {5, 9}], [{5, 9}, {5, 8}], [{5, 8}, {5, 7}], [{5, 7}, {4, 7}], [{4, 7}, {3, 7}], [{3, 7}, {2, 7}], [{2, 7}, {1, 7}], [{1, 7}, {0, 7}], [{0, 7}, {0, 8}], [{0, 8}, {0, 9}], [{0, 9}, {0, 10}] ]

candidates = [ [{2, 9}, {3, 9}], [{3, 9}, {4, 9}], [{4, 9}, {4, 8}], [{4, 8}, {3, 8}], [{3, 8}, {2, 8}], [{2, 8}, {2, 9}] ]

previous_edge = hd(connected)

{e_cand, _d} = EdgeTracer.find_closest_parallel_edge(previous_edge, candidates)
{e_conn, _d} = EdgeTracer.find_closest_parallel_edge(e_cand, connected)

islands3 = IdenticonSvg.generate("rRf5G", 6)

paths = islands3 |> Map.get(:paths)

pathset1 = hd(paths)

[a, b, c, d] = pathset1
