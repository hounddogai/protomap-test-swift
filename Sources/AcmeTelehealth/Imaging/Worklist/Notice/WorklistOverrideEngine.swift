import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist override calculation.
    protocol WorklistOverrideModifier {
        func describe() -> String
        func adjust(_ item: WorklistOverride, value: Double) -> Double
    }

    final class WorklistOverrideStartsAtOffsetAdjuster: WorklistOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: WorklistOverride, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class FlaggedWorklistOverrideAdjuster: WorklistOverrideModifier {
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

        func adjust(_ item: WorklistOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingWorklistOverrideAdjuster: WorklistOverrideModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WorklistOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumWorklistOverrideAdjuster: WorklistOverrideModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the worklist override steps in order and keeps a trace of each.
    final class WorklistOverrideEngine {
        var steps: [any WorklistOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WorklistOverride) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WorklistOverrideModifier = steps[index]
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

        func evaluateAll(_ items: [WorklistOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWorklistOverrideEngine(_ flags: Kit.Flags.Registry) -> WorklistOverrideEngine {
        return WorklistOverrideEngine(
            steps: [
                WorklistOverrideStartsAtOffsetAdjuster(weight: 0.2),
                FlaggedWorklistOverrideAdjuster(flags: flags, flag: "worklist-override-weighted", percent: 4.3),
                RoundingWorklistOverrideAdjuster(step: 0.5),
                MinimumWorklistOverrideAdjuster(minimum: 11.5),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 72197.1
        )
    }
}
