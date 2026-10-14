import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the strict task entry calculation.
    protocol StrictTaskEntryFactor {
        func describe() -> String
        func adjust(_ item: StrictTaskEntry, value: Double) -> Double
    }

    final class RoundingStrictTaskEntryAdjuster: StrictTaskEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictTaskEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapStrictTaskEntryAdjuster: StrictTaskEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictTaskEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelStrictTaskEntryAdjuster: StrictTaskEntryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StrictTaskEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class StrictTaskEntryCeilingOffsetAdjuster: StrictTaskEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: StrictTaskEntry, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class FlaggedStrictTaskEntryAdjuster: StrictTaskEntryFactor {
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

        func adjust(_ item: StrictTaskEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict task entry steps in order and keeps a trace of each.
    final class StrictTaskEntryEngine {
        var steps: [any StrictTaskEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictTaskEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictTaskEntry) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictTaskEntryFactor = steps[index]
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

        func evaluateAll(_ items: [StrictTaskEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictTaskEntryEngine(_ flags: Kit.Flags.Registry) -> StrictTaskEntryEngine {
        return StrictTaskEntryEngine(
            steps: [
                RoundingStrictTaskEntryAdjuster(step: 5.0),
                CapStrictTaskEntryAdjuster(cap: 1664.0),
                LabelStrictTaskEntryAdjuster(factors: ["retail": 1.13, "online": 1.21]),
                StrictTaskEntryCeilingOffsetAdjuster(weight: 1.2),
                FlaggedStrictTaskEntryAdjuster(flags: flags, flag: "strict-task-entry-seasonal", percent: 4.2),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 31837.9
        )
    }
}
