import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the capped task entry calculation.
    protocol CappedTaskEntryModifier {
        func describe() -> String
        func adjust(_ item: CappedTaskEntry, value: Double) -> Double
    }

    final class CappedTaskEntryDiscountOffsetAdjuster: CappedTaskEntryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: CappedTaskEntry, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class MinimumCappedTaskEntryAdjuster: CappedTaskEntryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedTaskEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedCappedTaskEntryAdjuster: CappedTaskEntryModifier {
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

        func adjust(_ item: CappedTaskEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped task entry steps in order and keeps a trace of each.
    final class CappedTaskEntryEngine {
        var steps: [any CappedTaskEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedTaskEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedTaskEntry) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [CappedTaskEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedTaskEntryEngine(_ flags: Kit.Flags.Registry) -> CappedTaskEntryEngine {
        return CappedTaskEntryEngine(
            steps: [
                CappedTaskEntryDiscountOffsetAdjuster(weight: 0.13),
                MinimumCappedTaskEntryAdjuster(minimum: 8.9),
                FlaggedCappedTaskEntryAdjuster(flags: flags, flag: "capped-task-entry-default", percent: 9.2),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 53334.0
        )
    }
}
