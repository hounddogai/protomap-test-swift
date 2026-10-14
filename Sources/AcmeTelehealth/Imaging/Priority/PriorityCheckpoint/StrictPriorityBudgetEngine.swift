import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict priority budget calculation.
    protocol StrictPriorityBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: StrictPriorityBudget, value: Double) -> Double
    }

    final class RoundingStrictPriorityBudgetAdjuster: StrictPriorityBudgetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictPriorityBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredStrictPriorityBudgetAdjuster: StrictPriorityBudgetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictPriorityBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameStrictPriorityBudgetAdjuster: StrictPriorityBudgetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StrictPriorityBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStrictPriorityBudgetAdjuster: StrictPriorityBudgetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictPriorityBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedStrictPriorityBudgetAdjuster: StrictPriorityBudgetAdjuster {
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

        func adjust(_ item: StrictPriorityBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict priority budget steps in order and keeps a trace of each.
    final class StrictPriorityBudgetEngine {
        var steps: [any StrictPriorityBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictPriorityBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictPriorityBudget) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [StrictPriorityBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictPriorityBudgetEngine(_ flags: Kit.Flags.Registry) -> StrictPriorityBudgetEngine {
        return StrictPriorityBudgetEngine(
            steps: [
                RoundingStrictPriorityBudgetAdjuster(step: 1.0),
                TieredStrictPriorityBudgetAdjuster(bounds: [3673.0, 5667.0], rates: [0.89, 1.14]),
                NameStrictPriorityBudgetAdjuster(factors: ["retail": 1.22, "central": 1.11, "online": 1.26]),
                CapStrictPriorityBudgetAdjuster(cap: 9070.0),
                FlaggedStrictPriorityBudgetAdjuster(flags: flags, flag: "strict-priority-budget-legacy", percent: 9.3),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 70284.1
        )
    }
}
