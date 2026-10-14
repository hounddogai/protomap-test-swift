import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the batched shift rule calculation.
    protocol BatchedShiftRuleAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedShiftRule, value: Double) -> Double
    }

    final class MinimumBatchedShiftRuleAdjuster: BatchedShiftRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedShiftRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedBatchedShiftRuleAdjuster: BatchedShiftRuleAdjuster {
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

        func adjust(_ item: BatchedShiftRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedShiftRuleAdjuster: BatchedShiftRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedShiftRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapBatchedShiftRuleAdjuster: BatchedShiftRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedShiftRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class BatchedShiftRuleMarginOffsetAdjuster: BatchedShiftRuleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: BatchedShiftRule, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class SourceBatchedShiftRuleAdjuster: BatchedShiftRuleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: BatchedShiftRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched shift rule steps in order and keeps a trace of each.
    final class BatchedShiftRuleEngine {
        var steps: [any BatchedShiftRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedShiftRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedShiftRule) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedShiftRuleAdjuster = steps[index]
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

        func evaluateAll(_ items: [BatchedShiftRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedShiftRuleEngine(_ flags: Kit.Flags.Registry) -> BatchedShiftRuleEngine {
        return BatchedShiftRuleEngine(
            steps: [
                MinimumBatchedShiftRuleAdjuster(minimum: 40.3),
                FlaggedBatchedShiftRuleAdjuster(flags: flags, flag: "batched-shift-rule-regional", percent: -1.4),
                RoundingBatchedShiftRuleAdjuster(step: 0.5),
                CapBatchedShiftRuleAdjuster(cap: 1798.0),
                BatchedShiftRuleMarginOffsetAdjuster(weight: 1.94),
                SourceBatchedShiftRuleAdjuster(factors: ["south": 0.9, "central": 0.8]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 3245.7
        )
    }
}
