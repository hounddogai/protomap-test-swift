import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted order set policy calculation.
    protocol WeightedOrderSetPolicyModifier {
        func describe() -> String
        func adjust(_ item: WeightedOrderSetPolicy, value: Double) -> Double
    }

    final class PercentWeightedOrderSetPolicyAdjuster: WeightedOrderSetPolicyModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedOrderSetPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WeightedOrderSetPolicyEndsAtOffsetAdjuster: WeightedOrderSetPolicyModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: WeightedOrderSetPolicy, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class CapWeightedOrderSetPolicyAdjuster: WeightedOrderSetPolicyModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedOrderSetPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelWeightedOrderSetPolicyAdjuster: WeightedOrderSetPolicyModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WeightedOrderSetPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted order set policy steps in order and keeps a trace of each.
    final class WeightedOrderSetPolicyEngine {
        var steps: [any WeightedOrderSetPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedOrderSetPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedOrderSetPolicy) -> Double {
            var current = item.projectedTotal()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [WeightedOrderSetPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedOrderSetPolicyEngine() -> WeightedOrderSetPolicyEngine {
        return WeightedOrderSetPolicyEngine(
            steps: [
                PercentWeightedOrderSetPolicyAdjuster(percent: 23.7),
                WeightedOrderSetPolicyEndsAtOffsetAdjuster(weight: 1.14),
                CapWeightedOrderSetPolicyAdjuster(cap: 40225.0),
                LabelWeightedOrderSetPolicyAdjuster(factors: ["retail": 1.32, "south": 0.92]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 63207.3
        )
    }
}
