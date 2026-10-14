import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the regional inventory policy calculation.
    protocol RegionalInventoryPolicyModifier {
        func describe() -> String
        func adjust(_ item: RegionalInventoryPolicy, value: Double) -> Double
    }

    final class PercentRegionalInventoryPolicyAdjuster: RegionalInventoryPolicyModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalInventoryPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleRegionalInventoryPolicyAdjuster: RegionalInventoryPolicyModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RegionalInventoryPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRegionalInventoryPolicyAdjuster: RegionalInventoryPolicyModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalInventoryPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional inventory policy steps in order and keeps a trace of each.
    final class RegionalInventoryPolicyEngine {
        var steps: [any RegionalInventoryPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalInventoryPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalInventoryPolicy) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [RegionalInventoryPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalInventoryPolicyEngine() -> RegionalInventoryPolicyEngine {
        return RegionalInventoryPolicyEngine(
            steps: [
                PercentRegionalInventoryPolicyAdjuster(percent: -18.5),
                TitleRegionalInventoryPolicyAdjuster(factors: ["north": 0.91, "east": 0.89]),
                RoundingRegionalInventoryPolicyAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 64445.6
        )
    }
}
