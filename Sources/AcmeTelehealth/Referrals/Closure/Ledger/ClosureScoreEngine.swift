import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure score calculation.
    protocol ClosureScoreModifier {
        func describe() -> String
        func adjust(_ item: ClosureScore, value: Double) -> Double
    }

    final class FlaggedClosureScoreAdjuster: ClosureScoreModifier {
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

        func adjust(_ item: ClosureScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumClosureScoreAdjuster: ClosureScoreModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapClosureScoreAdjuster: ClosureScoreModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleClosureScoreAdjuster: ClosureScoreModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ClosureScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingClosureScoreAdjuster: ClosureScoreModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentClosureScoreAdjuster: ClosureScoreModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the closure score steps in order and keeps a trace of each.
    final class ClosureScoreEngine {
        var steps: [any ClosureScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClosureScore) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureScoreModifier = steps[index]
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

        func evaluateAll(_ items: [ClosureScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClosureScoreEngine(_ flags: Kit.Flags.Registry) -> ClosureScoreEngine {
        return ClosureScoreEngine(
            steps: [
                FlaggedClosureScoreAdjuster(flags: flags, flag: "closure-score-legacy", percent: 8.1),
                MinimumClosureScoreAdjuster(minimum: 23.7),
                CapClosureScoreAdjuster(cap: 26528.0),
                TitleClosureScoreAdjuster(factors: ["retail": 1.1, "central": 1.23]),
                RoundingClosureScoreAdjuster(step: 5.0),
                PercentClosureScoreAdjuster(percent: 23.7),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 51234.2
        )
    }
}
