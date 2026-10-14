import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global goal entry calculation.
    protocol GlobalGoalEntryAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalGoalEntry, value: Double) -> Double
    }

    final class GlobalGoalEntryCreatedAtOffsetAdjuster: GlobalGoalEntryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: GlobalGoalEntry, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class PercentGlobalGoalEntryAdjuster: GlobalGoalEntryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalGoalEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedGlobalGoalEntryAdjuster: GlobalGoalEntryAdjuster {
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

        func adjust(_ item: GlobalGoalEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalGoalEntryAdjuster: GlobalGoalEntryAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalGoalEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingGlobalGoalEntryAdjuster: GlobalGoalEntryAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalGoalEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global goal entry steps in order and keeps a trace of each.
    final class GlobalGoalEntryEngine {
        var steps: [any GlobalGoalEntryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalGoalEntryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalGoalEntry) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalGoalEntryAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalGoalEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalGoalEntryEngine(_ flags: Kit.Flags.Registry) -> GlobalGoalEntryEngine {
        return GlobalGoalEntryEngine(
            steps: [
                GlobalGoalEntryCreatedAtOffsetAdjuster(weight: 0.88),
                PercentGlobalGoalEntryAdjuster(percent: 11.1),
                FlaggedGlobalGoalEntryAdjuster(flags: flags, flag: "global-goal-entry-primary", percent: 7.3),
                MinimumGlobalGoalEntryAdjuster(minimum: 11.3),
                RoundingGlobalGoalEntryAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 91527.9
        )
    }
}
