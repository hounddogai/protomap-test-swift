import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the capped modality policy calculation.
    protocol CappedModalityPolicyFactor {
        func describe() -> String
        func adjust(_ item: CappedModalityPolicy, value: Double) -> Double
    }

    final class PercentCappedModalityPolicyAdjuster: CappedModalityPolicyFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedModalityPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedModalityPolicyAdjuster: CappedModalityPolicyFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedModalityPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCappedModalityPolicyAdjuster: CappedModalityPolicyFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedModalityPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CappedModalityPolicyCostOffsetAdjuster: CappedModalityPolicyFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: CappedModalityPolicy, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class WardCappedModalityPolicyAdjuster: CappedModalityPolicyFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: CappedModalityPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCappedModalityPolicyAdjuster: CappedModalityPolicyFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedModalityPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped modality policy steps in order and keeps a trace of each.
    final class CappedModalityPolicyEngine {
        var steps: [any CappedModalityPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedModalityPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedModalityPolicy) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedModalityPolicyFactor = steps[index]
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

        func evaluateAll(_ items: [CappedModalityPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedModalityPolicyEngine() -> CappedModalityPolicyEngine {
        return CappedModalityPolicyEngine(
            steps: [
                PercentCappedModalityPolicyAdjuster(percent: -20.6),
                CapCappedModalityPolicyAdjuster(cap: 12689.0),
                RoundingCappedModalityPolicyAdjuster(step: 5.0),
                CappedModalityPolicyCostOffsetAdjuster(weight: 0.99),
                WardCappedModalityPolicyAdjuster(factors: ["online": 1.12, "retail": 1.31]),
                MinimumCappedModalityPolicyAdjuster(minimum: 21.1),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 3375.8
        )
    }
}
