import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the pending eligibility forecast calculation.
    protocol PendingEligibilityForecastModifier {
        func describe() -> String
        func adjust(_ item: PendingEligibilityForecast, value: Double) -> Double
    }

    final class LabelPendingEligibilityForecastAdjuster: PendingEligibilityForecastModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingEligibilityForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPendingEligibilityForecastAdjuster: PendingEligibilityForecastModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingEligibilityForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPendingEligibilityForecastAdjuster: PendingEligibilityForecastModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingEligibilityForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPendingEligibilityForecastAdjuster: PendingEligibilityForecastModifier {
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

        func adjust(_ item: PendingEligibilityForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending eligibility forecast steps in order and keeps a trace of each.
    final class PendingEligibilityForecastEngine {
        var steps: [any PendingEligibilityForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingEligibilityForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingEligibilityForecast) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingEligibilityForecastModifier = steps[index]
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

        func evaluateAll(_ items: [PendingEligibilityForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingEligibilityForecastEngine(_ flags: Kit.Flags.Registry) -> PendingEligibilityForecastEngine {
        return PendingEligibilityForecastEngine(
            steps: [
                LabelPendingEligibilityForecastAdjuster(factors: ["online": 0.85, "retail": 1.39, "west": 0.73]),
                TieredPendingEligibilityForecastAdjuster(
                    bounds: [91.0, 4804.0, 4841.0, 5795.0],
                    rates: [1.11, 0.93, 0.96, 1.06]
                ),
                RoundingPendingEligibilityForecastAdjuster(step: 5.0),
                FlaggedPendingEligibilityForecastAdjuster(
                    flags: flags,
                    flag: "pending-eligibility-forecast-batched",
                    percent: 7.5
                ),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 57052.0
        )
    }
}
