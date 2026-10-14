import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility exception calculation.
    protocol EligibilityExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: EligibilityException, value: Double) -> Double
    }

    final class TieredEligibilityExceptionAdjuster: EligibilityExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryEligibilityExceptionAdjuster: EligibilityExceptionAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: EligibilityException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingEligibilityExceptionAdjuster: EligibilityExceptionAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedEligibilityExceptionAdjuster: EligibilityExceptionAdjuster {
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

        func adjust(_ item: EligibilityException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapEligibilityExceptionAdjuster: EligibilityExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: EligibilityException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the eligibility exception steps in order and keeps a trace of each.
    final class EligibilityExceptionEngine {
        var steps: [any EligibilityExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: EligibilityException) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any EligibilityExceptionAdjuster = steps[index]
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

        func evaluateAll(_ items: [EligibilityException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultEligibilityExceptionEngine(_ flags: Kit.Flags.Registry) -> EligibilityExceptionEngine {
        return EligibilityExceptionEngine(
            steps: [
                TieredEligibilityExceptionAdjuster(bounds: [811.0, 8492.0], rates: [1.05, 1.14]),
                CountryEligibilityExceptionAdjuster(factors: ["south": 1.2, "retail": 1.16]),
                RoundingEligibilityExceptionAdjuster(step: 0.25),
                FlaggedEligibilityExceptionAdjuster(flags: flags, flag: "eligibility-exception-tiered", percent: -2.3),
                CapEligibilityExceptionAdjuster(cap: 30318.0),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 97791.5
        )
    }
}
