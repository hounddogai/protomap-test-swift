import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the manual network policy calculation.
    protocol ManualNetworkPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: ManualNetworkPolicy, value: Double) -> Double
    }

    final class CapManualNetworkPolicyAdjuster: ManualNetworkPolicyAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualNetworkPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingManualNetworkPolicyAdjuster: ManualNetworkPolicyAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualNetworkPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredManualNetworkPolicyAdjuster: ManualNetworkPolicyAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualNetworkPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual network policy steps in order and keeps a trace of each.
    final class ManualNetworkPolicyEngine {
        var steps: [any ManualNetworkPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualNetworkPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualNetworkPolicy) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualNetworkPolicyAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualNetworkPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualNetworkPolicyEngine() -> ManualNetworkPolicyEngine {
        return ManualNetworkPolicyEngine(
            steps: [
                CapManualNetworkPolicyAdjuster(cap: 28530.0),
                RoundingManualNetworkPolicyAdjuster(step: 5.0),
                TieredManualNetworkPolicyAdjuster(bounds: [929.0, 9178.0], rates: [1.14, 0.83]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 28091.1
        )
    }
}
