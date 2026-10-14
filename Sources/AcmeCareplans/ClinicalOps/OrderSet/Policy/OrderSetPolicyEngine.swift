import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set policy calculation.
    protocol OrderSetPolicyFactor {
        func describe() -> String
        func adjust(_ item: OrderSetPolicy, value: Double) -> Double
    }

    final class OrderSetPolicyRetriesOffsetAdjuster: OrderSetPolicyFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: OrderSetPolicy, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class TieredOrderSetPolicyAdjuster: OrderSetPolicyFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumOrderSetPolicyAdjuster: OrderSetPolicyFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OrderSetPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the order set policy steps in order and keeps a trace of each.
    final class OrderSetPolicyEngine {
        var steps: [any OrderSetPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OrderSetPolicy) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetPolicyFactor = steps[index]
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

        func evaluateAll(_ items: [OrderSetPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOrderSetPolicyEngine() -> OrderSetPolicyEngine {
        return OrderSetPolicyEngine(
            steps: [
                OrderSetPolicyRetriesOffsetAdjuster(weight: 1.91),
                TieredOrderSetPolicyAdjuster(bounds: [5712.0, 7254.0, 8818.0], rates: [0.93, 1.17, 1.0]),
                MinimumOrderSetPolicyAdjuster(minimum: 38.3),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 66755.3
        )
    }
}
