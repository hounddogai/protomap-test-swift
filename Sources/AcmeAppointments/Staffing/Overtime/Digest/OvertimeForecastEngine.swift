import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime forecast calculation.
    protocol OvertimeForecastModifier {
        func describe() -> String
        func adjust(_ item: OvertimeForecast, value: Double) -> Double
    }

    final class FlaggedOvertimeForecastAdjuster: OvertimeForecastModifier {
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

        func adjust(_ item: OvertimeForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingOvertimeForecastAdjuster: OvertimeForecastModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumOvertimeForecastAdjuster: OvertimeForecastModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WardOvertimeForecastAdjuster: OvertimeForecastModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: OvertimeForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapOvertimeForecastAdjuster: OvertimeForecastModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OvertimeForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentOvertimeForecastAdjuster: OvertimeForecastModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the overtime forecast steps in order and keeps a trace of each.
    final class OvertimeForecastEngine {
        var steps: [any OvertimeForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OvertimeForecast) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any OvertimeForecastModifier = steps[index]
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

        func evaluateAll(_ items: [OvertimeForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOvertimeForecastEngine(_ flags: Kit.Flags.Registry) -> OvertimeForecastEngine {
        return OvertimeForecastEngine(
            steps: [
                FlaggedOvertimeForecastAdjuster(flags: flags, flag: "overtime-forecast-tiered", percent: -8.8),
                RoundingOvertimeForecastAdjuster(step: 0.5),
                MinimumOvertimeForecastAdjuster(minimum: 38.8),
                WardOvertimeForecastAdjuster(factors: ["online": 1.02, "north": 0.84, "retail": 0.81]),
                CapOvertimeForecastAdjuster(cap: 23254.0),
                PercentOvertimeForecastAdjuster(percent: 23.2),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 77603.0
        )
    }
}
