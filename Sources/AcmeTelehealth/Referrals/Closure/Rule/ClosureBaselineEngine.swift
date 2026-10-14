import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure baseline calculation.
    protocol ClosureBaselineFactor {
        func describe() -> String
        func adjust(_ item: ClosureBaseline, value: Double) -> Double
    }

    final class FlaggedClosureBaselineAdjuster: ClosureBaselineFactor {
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

        func adjust(_ item: ClosureBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumClosureBaselineAdjuster: ClosureBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingClosureBaselineAdjuster: ClosureBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the closure baseline steps in order and keeps a trace of each.
    final class ClosureBaselineEngine {
        var steps: [any ClosureBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClosureBaseline) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureBaselineFactor = steps[index]
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

        func evaluateAll(_ items: [ClosureBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClosureBaselineEngine(_ flags: Kit.Flags.Registry) -> ClosureBaselineEngine {
        return ClosureBaselineEngine(
            steps: [
                FlaggedClosureBaselineAdjuster(flags: flags, flag: "closure-baseline-tiered", percent: -3.2),
                MinimumClosureBaselineAdjuster(minimum: 44.8),
                RoundingClosureBaselineAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 21460.5
        )
    }
}
