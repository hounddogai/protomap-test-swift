import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global task override calculation.
    protocol GlobalTaskOverrideFactor {
        func describe() -> String
        func adjust(_ item: GlobalTaskOverride, value: Double) -> Double
    }

    final class RoundingGlobalTaskOverrideAdjuster: GlobalTaskOverrideFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalTaskOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapGlobalTaskOverrideAdjuster: GlobalTaskOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalTaskOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleGlobalTaskOverrideAdjuster: GlobalTaskOverrideFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GlobalTaskOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedGlobalTaskOverrideAdjuster: GlobalTaskOverrideFactor {
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

        func adjust(_ item: GlobalTaskOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalTaskOverrideAdjuster: GlobalTaskOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalTaskOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGlobalTaskOverrideAdjuster: GlobalTaskOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalTaskOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global task override steps in order and keeps a trace of each.
    final class GlobalTaskOverrideEngine {
        var steps: [any GlobalTaskOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalTaskOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalTaskOverride) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalTaskOverrideFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalTaskOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalTaskOverrideEngine(_ flags: Kit.Flags.Registry) -> GlobalTaskOverrideEngine {
        return GlobalTaskOverrideEngine(
            steps: [
                RoundingGlobalTaskOverrideAdjuster(step: 5.0),
                CapGlobalTaskOverrideAdjuster(cap: 48678.0),
                TitleGlobalTaskOverrideAdjuster(factors: ["central": 1.32, "online": 0.95, "retail": 1.35]),
                FlaggedGlobalTaskOverrideAdjuster(flags: flags, flag: "global-task-override-global", percent: -6.1),
                MinimumGlobalTaskOverrideAdjuster(minimum: 25.8),
                PercentGlobalTaskOverrideAdjuster(percent: -14.4),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 34679.7
        )
    }
}
