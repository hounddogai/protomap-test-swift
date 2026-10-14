import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility plan calculation.
    protocol EligibilityPlanFactor {
        func describe() -> String
        func adjust(_ item: EligibilityPlan, value: Double) -> Double
    }

    final class PercentEligibilityPlanAdjuster: EligibilityPlanFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingEligibilityPlanAdjuster: EligibilityPlanFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleEligibilityPlanAdjuster: EligibilityPlanFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: EligibilityPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumEligibilityPlanAdjuster: EligibilityPlanFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilityPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the eligibility plan steps in order and keeps a trace of each.
    final class EligibilityPlanEngine {
        var steps: [any EligibilityPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: EligibilityPlan) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any EligibilityPlanFactor = steps[index]
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

        func evaluateAll(_ items: [EligibilityPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultEligibilityPlanEngine() -> EligibilityPlanEngine {
        return EligibilityPlanEngine(
            steps: [
                PercentEligibilityPlanAdjuster(percent: 2.3),
                RoundingEligibilityPlanAdjuster(step: 0.25),
                TitleEligibilityPlanAdjuster(factors: ["central": 1.14, "east": 1.37, "south": 0.89]),
                MinimumEligibilityPlanAdjuster(minimum: 3.2),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 76876.7
        )
    }
}
