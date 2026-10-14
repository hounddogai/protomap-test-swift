import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result entry calculation.
    protocol ResultEntryModifier {
        func describe() -> String
        func adjust(_ item: ResultEntry, value: Double) -> Double
    }

    final class CapResultEntryAdjuster: ResultEntryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ResultEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocaleResultEntryAdjuster: ResultEntryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ResultEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedResultEntryAdjuster: ResultEntryModifier {
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

        func adjust(_ item: ResultEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the result entry steps in order and keeps a trace of each.
    final class ResultEntryEngine {
        var steps: [any ResultEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ResultEntry) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ResultEntryModifier = steps[index]
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

        func evaluateAll(_ items: [ResultEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultResultEntryEngine(_ flags: Kit.Flags.Registry) -> ResultEntryEngine {
        return ResultEntryEngine(
            steps: [
                CapResultEntryAdjuster(cap: 29016.0),
                LocaleResultEntryAdjuster(factors: ["retail": 1.03, "east": 1.2]),
                FlaggedResultEntryAdjuster(flags: flags, flag: "result-entry-lenient", percent: -1.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 84639.5
        )
    }
}
