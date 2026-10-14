import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding forecast calculation.
    protocol RoundingForecastFactor {
        func describe() -> String
        func adjust(_ item: RoundingForecast, value: Double) -> Double
    }

    final class CapRoundingForecastAdjuster: RoundingForecastFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRoundingForecastAdjuster: RoundingForecastFactor {
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

        func adjust(_ item: RoundingForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingForecastLimitOffsetAdjuster: RoundingForecastFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: RoundingForecast, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the rounding forecast steps in order and keeps a trace of each.
    final class RoundingForecastEngine {
        var steps: [any RoundingForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RoundingForecast) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingForecastFactor = steps[index]
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

        func evaluateAll(_ items: [RoundingForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRoundingForecastEngine(_ flags: Kit.Flags.Registry) -> RoundingForecastEngine {
        return RoundingForecastEngine(
            steps: [
                CapRoundingForecastAdjuster(cap: 47157.0),
                FlaggedRoundingForecastAdjuster(flags: flags, flag: "rounding-forecast-rolling", percent: 9.0),
                RoundingForecastLimitOffsetAdjuster(weight: 0.81),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 28917.6
        )
    }
}
