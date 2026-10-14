import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the manual closure rollup calculation.
    protocol ManualClosureRollupFactor {
        func describe() -> String
        func adjust(_ item: ManualClosureRollup, value: Double) -> Double
    }

    final class PercentManualClosureRollupAdjuster: ManualClosureRollupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualClosureRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedManualClosureRollupAdjuster: ManualClosureRollupFactor {
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

        func adjust(_ item: ManualClosureRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualClosureRollupAdjuster: ManualClosureRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualClosureRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual closure rollup steps in order and keeps a trace of each.
    final class ManualClosureRollupEngine {
        var steps: [any ManualClosureRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualClosureRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualClosureRollup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualClosureRollupFactor = steps[index]
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

        func evaluateAll(_ items: [ManualClosureRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualClosureRollupEngine(_ flags: Kit.Flags.Registry) -> ManualClosureRollupEngine {
        return ManualClosureRollupEngine(
            steps: [
                PercentManualClosureRollupAdjuster(percent: -24.7),
                FlaggedManualClosureRollupAdjuster(flags: flags, flag: "manual-closure-rollup-rolling", percent: -3.4),
                MinimumManualClosureRollupAdjuster(minimum: 36.1),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 54752.2
        )
    }
}
