import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the scheduled float pool budget calculation.
    protocol ScheduledFloatPoolBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledFloatPoolBudget, value: Double) -> Double
    }

    final class RegionScheduledFloatPoolBudgetAdjuster: ScheduledFloatPoolBudgetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ScheduledFloatPoolBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapScheduledFloatPoolBudgetAdjuster: ScheduledFloatPoolBudgetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledFloatPoolBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumScheduledFloatPoolBudgetAdjuster: ScheduledFloatPoolBudgetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledFloatPoolBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the scheduled float pool budget steps in order and keeps a trace of each.
    final class ScheduledFloatPoolBudgetEngine {
        var steps: [any ScheduledFloatPoolBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledFloatPoolBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledFloatPoolBudget) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledFloatPoolBudgetAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledFloatPoolBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledFloatPoolBudgetEngine() -> ScheduledFloatPoolBudgetEngine {
        return ScheduledFloatPoolBudgetEngine(
            steps: [
                RegionScheduledFloatPoolBudgetAdjuster(factors: ["retail": 1.21, "east": 1.36, "central": 0.74]),
                CapScheduledFloatPoolBudgetAdjuster(cap: 11250.0),
                MinimumScheduledFloatPoolBudgetAdjuster(minimum: 44.7),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 43615.6
        )
    }
}
