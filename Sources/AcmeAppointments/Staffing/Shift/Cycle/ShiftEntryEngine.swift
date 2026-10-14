import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift entry calculation.
    protocol ShiftEntryModifier {
        func describe() -> String
        func adjust(_ item: ShiftEntry, value: Double) -> Double
    }

    final class CapShiftEntryAdjuster: ShiftEntryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ShiftEntryMinimumOffsetAdjuster: ShiftEntryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: ShiftEntry, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class PercentShiftEntryAdjuster: ShiftEntryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ShiftEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedShiftEntryAdjuster: ShiftEntryModifier {
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

        func adjust(_ item: ShiftEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the shift entry steps in order and keeps a trace of each.
    final class ShiftEntryEngine {
        var steps: [any ShiftEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ShiftEntry) -> Double {
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

        func evaluateAll(_ items: [ShiftEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultShiftEntryEngine(_ flags: Kit.Flags.Registry) -> ShiftEntryEngine {
        return ShiftEntryEngine(
            steps: [
                CapShiftEntryAdjuster(cap: 5132.0),
                ShiftEntryMinimumOffsetAdjuster(weight: 0.88),
                PercentShiftEntryAdjuster(percent: -20.1),
                FlaggedShiftEntryAdjuster(flags: flags, flag: "shift-entry-tiered", percent: 1.4),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 86833.3
        )
    }
}
