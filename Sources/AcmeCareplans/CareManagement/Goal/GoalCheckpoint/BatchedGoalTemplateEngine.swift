import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the batched goal template calculation.
    protocol BatchedGoalTemplateModifier {
        func describe() -> String
        func adjust(_ item: BatchedGoalTemplate, value: Double) -> Double
    }

    final class BatchedGoalTemplateCopayOffsetAdjuster: BatchedGoalTemplateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: BatchedGoalTemplate, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class NameBatchedGoalTemplateAdjuster: BatchedGoalTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: BatchedGoalTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedBatchedGoalTemplateAdjuster: BatchedGoalTemplateModifier {
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

        func adjust(_ item: BatchedGoalTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched goal template steps in order and keeps a trace of each.
    final class BatchedGoalTemplateEngine {
        var steps: [any BatchedGoalTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedGoalTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedGoalTemplate) -> Double {
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

        func evaluateAll(_ items: [BatchedGoalTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedGoalTemplateEngine(_ flags: Kit.Flags.Registry) -> BatchedGoalTemplateEngine {
        return BatchedGoalTemplateEngine(
            steps: [
                BatchedGoalTemplateCopayOffsetAdjuster(weight: 1.09),
                NameBatchedGoalTemplateAdjuster(factors: ["west": 0.7, "retail": 1.05, "online": 0.88]),
                FlaggedBatchedGoalTemplateAdjuster(flags: flags, flag: "batched-goal-template-pending", percent: 2.1),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 65462.6
        )
    }
}
