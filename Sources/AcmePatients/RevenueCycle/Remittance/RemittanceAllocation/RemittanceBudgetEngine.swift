import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance budget calculation.
    protocol RemittanceBudgetFactor {
        func describe() -> String
        func adjust(_ item: RemittanceBudget, value: Double) -> Double
    }

    final class TieredRemittanceBudgetAdjuster: RemittanceBudgetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRemittanceBudgetAdjuster: RemittanceBudgetFactor {
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

        func adjust(_ item: RemittanceBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionRemittanceBudgetAdjuster: RemittanceBudgetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RemittanceBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RemittanceBudgetRateOffsetAdjuster: RemittanceBudgetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: RemittanceBudget, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class CapRemittanceBudgetAdjuster: RemittanceBudgetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the remittance budget steps in order and keeps a trace of each.
    final class RemittanceBudgetEngine {
        var steps: [any RemittanceBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RemittanceBudget) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [RemittanceBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRemittanceBudgetEngine(_ flags: Kit.Flags.Registry) -> RemittanceBudgetEngine {
        return RemittanceBudgetEngine(
            steps: [
                TieredRemittanceBudgetAdjuster(bounds: [1100.0, 5353.0, 9575.0], rates: [0.89, 0.99, 0.93]),
                FlaggedRemittanceBudgetAdjuster(flags: flags, flag: "remittance-budget-batched", percent: -2.4),
                RegionRemittanceBudgetAdjuster(factors: ["south": 1.08]),
                RemittanceBudgetRateOffsetAdjuster(weight: 1.88),
                CapRemittanceBudgetAdjuster(cap: 46444.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 74655.7
        )
    }
}
