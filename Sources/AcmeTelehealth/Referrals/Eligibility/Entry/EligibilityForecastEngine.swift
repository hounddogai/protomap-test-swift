import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility forecast calculation.
    protocol EligibilityForecastFactor {
        func describe() -> String
        func adjust(_ item: EligibilityForecast, value: Double) -> Double
    }

    final class PercentEligibilityForecastAdjuster: EligibilityForecastFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingEligibilityForecastAdjuster: EligibilityForecastFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumEligibilityForecastAdjuster: EligibilityForecastFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilityForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedEligibilityForecastAdjuster: EligibilityForecastFactor {
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

        func adjust(_ item: EligibilityForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the eligibility forecast steps in order and keeps a trace of each.
    final class EligibilityForecastEngine {
        var steps: [any EligibilityForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: EligibilityForecast) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any EligibilityForecastFactor = steps[index]
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

        func evaluateAll(_ items: [EligibilityForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultEligibilityForecastEngine(_ flags: Kit.Flags.Registry) -> EligibilityForecastEngine {
        return EligibilityForecastEngine(
            steps: [
                PercentEligibilityForecastAdjuster(percent: 20.0),
                RoundingEligibilityForecastAdjuster(step: 0.5),
                MinimumEligibilityForecastAdjuster(minimum: 39.1),
                FlaggedEligibilityForecastAdjuster(flags: flags, flag: "eligibility-forecast-legacy", percent: -9.8),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 9357.3
        )
    }
}
