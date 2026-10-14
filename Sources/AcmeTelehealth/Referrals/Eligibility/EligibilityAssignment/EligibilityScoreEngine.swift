import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility score calculation.
    protocol EligibilityScoreStep {
        func describe() -> String
        func adjust(_ item: EligibilityScore, value: Double) -> Double
    }

    final class CapEligibilityScoreAdjuster: EligibilityScoreStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: EligibilityScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredEligibilityScoreAdjuster: EligibilityScoreStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumEligibilityScoreAdjuster: EligibilityScoreStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilityScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelEligibilityScoreAdjuster: EligibilityScoreStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: EligibilityScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the eligibility score steps in order and keeps a trace of each.
    final class EligibilityScoreEngine {
        var steps: [any EligibilityScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: EligibilityScore) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any EligibilityScoreStep = steps[index]
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

        func evaluateAll(_ items: [EligibilityScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultEligibilityScoreEngine() -> EligibilityScoreEngine {
        return EligibilityScoreEngine(
            steps: [
                CapEligibilityScoreAdjuster(cap: 22738.0),
                TieredEligibilityScoreAdjuster(
                    bounds: [2130.0, 7346.0, 8678.0, 9020.0],
                    rates: [1.09, 1.06, 0.89, 1.07]
                ),
                MinimumEligibilityScoreAdjuster(minimum: 41.8),
                LabelEligibilityScoreAdjuster(factors: ["retail": 1.0, "central": 0.73]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 36353.8
        )
    }
}
