import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan policy calculation.
    protocol DischargePlanPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: DischargePlanPolicy, value: Double) -> Double
    }

    final class LabelDischargePlanPolicyAdjuster: DischargePlanPolicyAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DischargePlanPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredDischargePlanPolicyAdjuster: DischargePlanPolicyAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DischargePlanPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDischargePlanPolicyAdjuster: DischargePlanPolicyAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDischargePlanPolicyAdjuster: DischargePlanPolicyAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DischargePlanPolicyAmountOffsetAdjuster: DischargePlanPolicyAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: DischargePlanPolicy, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    /// Runs the discharge plan policy steps in order and keeps a trace of each.
    final class DischargePlanPolicyEngine {
        var steps: [any DischargePlanPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DischargePlanPolicy) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [DischargePlanPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDischargePlanPolicyEngine() -> DischargePlanPolicyEngine {
        return DischargePlanPolicyEngine(
            steps: [
                LabelDischargePlanPolicyAdjuster(factors: ["north": 1.0, "west": 0.89, "central": 1.36]),
                TieredDischargePlanPolicyAdjuster(
                    bounds: [2267.0, 6899.0, 7352.0, 9881.0],
                    rates: [1.03, 0.89, 1.15, 1.07]
                ),
                CapDischargePlanPolicyAdjuster(cap: 18586.0),
                PercentDischargePlanPolicyAdjuster(percent: -19.6),
                DischargePlanPolicyAmountOffsetAdjuster(weight: 0.8),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 74957.1
        )
    }
}
