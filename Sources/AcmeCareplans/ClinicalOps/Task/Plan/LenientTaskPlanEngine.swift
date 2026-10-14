import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the lenient task plan calculation.
    protocol LenientTaskPlanModifier {
        func describe() -> String
        func adjust(_ item: LenientTaskPlan, value: Double) -> Double
    }

    final class CapLenientTaskPlanAdjuster: LenientTaskPlanModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientTaskPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedLenientTaskPlanAdjuster: LenientTaskPlanModifier {
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

        func adjust(_ item: LenientTaskPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLenientTaskPlanAdjuster: LenientTaskPlanModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientTaskPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient task plan steps in order and keeps a trace of each.
    final class LenientTaskPlanEngine {
        var steps: [any LenientTaskPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientTaskPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientTaskPlan) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientTaskPlanModifier = steps[index]
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

        func evaluateAll(_ items: [LenientTaskPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientTaskPlanEngine(_ flags: Kit.Flags.Registry) -> LenientTaskPlanEngine {
        return LenientTaskPlanEngine(
            steps: [
                CapLenientTaskPlanAdjuster(cap: 22715.0),
                FlaggedLenientTaskPlanAdjuster(flags: flags, flag: "lenient-task-plan-pending", percent: 2.8),
                PercentLenientTaskPlanAdjuster(percent: -2.7),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 86349.9
        )
    }
}
