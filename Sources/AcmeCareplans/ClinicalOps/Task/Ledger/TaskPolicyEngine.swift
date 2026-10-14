import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task policy calculation.
    protocol TaskPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: TaskPolicy, value: Double) -> Double
    }

    final class PercentTaskPolicyAdjuster: TaskPolicyAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TaskPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTaskPolicyAdjuster: TaskPolicyAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingTaskPolicyAdjuster: TaskPolicyAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TaskPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedTaskPolicyAdjuster: TaskPolicyAdjuster {
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

        func adjust(_ item: TaskPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryTaskPolicyAdjuster: TaskPolicyAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: TaskPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the task policy steps in order and keeps a trace of each.
    final class TaskPolicyEngine {
        var steps: [any TaskPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TaskPolicy) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [TaskPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTaskPolicyEngine(_ flags: Kit.Flags.Registry) -> TaskPolicyEngine {
        return TaskPolicyEngine(
            steps: [
                PercentTaskPolicyAdjuster(percent: 3.8),
                TieredTaskPolicyAdjuster(bounds: [5057.0, 7058.0, 8089.0, 8347.0], rates: [1.0, 1.19, 1.04, 1.04]),
                RoundingTaskPolicyAdjuster(step: 5.0),
                FlaggedTaskPolicyAdjuster(flags: flags, flag: "task-policy-fallback", percent: -1.3),
                CategoryTaskPolicyAdjuster(factors: ["north": 1.03, "online": 1.03]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 70709.8
        )
    }
}
