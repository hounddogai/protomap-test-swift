import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the strict bed board forecast calculation.
    protocol StrictBedBoardForecastFactor {
        func describe() -> String
        func adjust(_ item: StrictBedBoardForecast, value: Double) -> Double
    }

    final class FlaggedStrictBedBoardForecastAdjuster: StrictBedBoardForecastFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: StrictBedBoardForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStrictBedBoardForecastAdjuster: StrictBedBoardForecastFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictBedBoardForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StrictBedBoardForecastCapacityOffsetAdjuster: StrictBedBoardForecastFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: StrictBedBoardForecast, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class TieredStrictBedBoardForecastAdjuster: StrictBedBoardForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictBedBoardForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict bed board forecast steps in order and keeps a trace of each.
    final class StrictBedBoardForecastEngine {
        var steps: [any StrictBedBoardForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictBedBoardForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictBedBoardForecast) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictBedBoardForecastFactor = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [StrictBedBoardForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictBedBoardForecastEngine(_ flags: Kit.Flags.Registry) -> StrictBedBoardForecastEngine {
        return StrictBedBoardForecastEngine(
            steps: [
                FlaggedStrictBedBoardForecastAdjuster(
                    flags: flags,
                    flag: "strict-bed-board-forecast-regional",
                    percent: -4.7
                ),
                RoundingStrictBedBoardForecastAdjuster(step: 0.05),
                StrictBedBoardForecastCapacityOffsetAdjuster(weight: 0.52),
                TieredStrictBedBoardForecastAdjuster(
                    bounds: [252.0, 1800.0, 5681.0, 9682.0],
                    rates: [1.13, 1.08, 1.07, 0.86]
                ),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 32172.4
        )
    }
}
