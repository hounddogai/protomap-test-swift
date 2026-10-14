import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read score calculation.
    protocol ReadScoreModifier {
        func describe() -> String
        func adjust(_ item: ReadScore, value: Double) -> Double
    }

    final class RoundingReadScoreAdjuster: ReadScoreModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapReadScoreAdjuster: ReadScoreModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedReadScoreAdjuster: ReadScoreModifier {
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

        func adjust(_ item: ReadScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the read score steps in order and keeps a trace of each.
    final class ReadScoreEngine {
        var steps: [any ReadScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReadScore) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ReadScoreModifier = steps[index]
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

        func evaluateAll(_ items: [ReadScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReadScoreEngine(_ flags: Kit.Flags.Registry) -> ReadScoreEngine {
        return ReadScoreEngine(
            steps: [
                RoundingReadScoreAdjuster(step: 0.25),
                CapReadScoreAdjuster(cap: 2925.0),
                FlaggedReadScoreAdjuster(flags: flags, flag: "read-score-seasonal", percent: 9.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 63329.1
        )
    }
}
