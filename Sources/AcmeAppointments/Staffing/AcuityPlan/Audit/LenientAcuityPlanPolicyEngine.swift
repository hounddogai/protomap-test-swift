import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the lenient acuity plan policy calculation.
    protocol LenientAcuityPlanPolicyStep {
        func describe() -> String
        func adjust(_ item: LenientAcuityPlanPolicy, value: Double) -> Double
    }

    final class RoundingLenientAcuityPlanPolicyAdjuster: LenientAcuityPlanPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientAcuityPlanPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelLenientAcuityPlanPolicyAdjuster: LenientAcuityPlanPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientAcuityPlanPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentLenientAcuityPlanPolicyAdjuster: LenientAcuityPlanPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientAcuityPlanPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientAcuityPlanPolicyDosageMgOffsetAdjuster: LenientAcuityPlanPolicyStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: LenientAcuityPlanPolicy, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class MinimumLenientAcuityPlanPolicyAdjuster: LenientAcuityPlanPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientAcuityPlanPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient acuity plan policy steps in order and keeps a trace of each.
    final class LenientAcuityPlanPolicyEngine {
        var steps: [any LenientAcuityPlanPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientAcuityPlanPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientAcuityPlanPolicy) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientAcuityPlanPolicyStep = steps[index]
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

        func evaluateAll(_ items: [LenientAcuityPlanPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientAcuityPlanPolicyEngine() -> LenientAcuityPlanPolicyEngine {
        return LenientAcuityPlanPolicyEngine(
            steps: [
                RoundingLenientAcuityPlanPolicyAdjuster(step: 5.0),
                LabelLenientAcuityPlanPolicyAdjuster(factors: ["retail": 1.17, "east": 1.11]),
                PercentLenientAcuityPlanPolicyAdjuster(percent: -24.9),
                LenientAcuityPlanPolicyDosageMgOffsetAdjuster(weight: 0.2),
                MinimumLenientAcuityPlanPolicyAdjuster(minimum: 28.1),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 47043.3
        )
    }
}
