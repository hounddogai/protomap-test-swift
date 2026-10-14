import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier score calculation.
    protocol CourierScoreFactor {
        func describe() -> String
        func adjust(_ item: CourierScore, value: Double) -> Double
    }

    final class PercentCourierScoreAdjuster: CourierScoreFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CourierScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCourierScoreAdjuster: CourierScoreFactor {
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

        func adjust(_ item: CourierScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCourierScoreAdjuster: CourierScoreFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapCourierScoreAdjuster: CourierScoreFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the courier score steps in order and keeps a trace of each.
    final class CourierScoreEngine {
        var steps: [any CourierScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CourierScore) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [CourierScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCourierScoreEngine(_ flags: Kit.Flags.Registry) -> CourierScoreEngine {
        return CourierScoreEngine(
            steps: [
                PercentCourierScoreAdjuster(percent: 17.8),
                FlaggedCourierScoreAdjuster(flags: flags, flag: "courier-score-pending", percent: -8.6),
                RoundingCourierScoreAdjuster(step: 5.0),
                CapCourierScoreAdjuster(cap: 46835.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 81291.4
        )
    }
}
