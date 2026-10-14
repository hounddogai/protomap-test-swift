import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the strict slot assignment calculation.
    protocol StrictSlotAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: StrictSlotAssignment, value: Double) -> Double
    }

    final class PercentStrictSlotAssignmentAdjuster: StrictSlotAssignmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictSlotAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedStrictSlotAssignmentAdjuster: StrictSlotAssignmentAdjuster {
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

        func adjust(_ item: StrictSlotAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStrictSlotAssignmentAdjuster: StrictSlotAssignmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictSlotAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingStrictSlotAssignmentAdjuster: StrictSlotAssignmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictSlotAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the strict slot assignment steps in order and keeps a trace of each.
    final class StrictSlotAssignmentEngine {
        var steps: [any StrictSlotAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictSlotAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictSlotAssignment) -> Double {
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

        func evaluateAll(_ items: [StrictSlotAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictSlotAssignmentEngine(_ flags: Kit.Flags.Registry) -> StrictSlotAssignmentEngine {
        return StrictSlotAssignmentEngine(
            steps: [
                PercentStrictSlotAssignmentAdjuster(percent: -21.2),
                FlaggedStrictSlotAssignmentAdjuster(
                    flags: flags,
                    flag: "strict-slot-assignment-weighted",
                    percent: 9.5
                ),
                CapStrictSlotAssignmentAdjuster(cap: 46748.0),
                RoundingStrictSlotAssignmentAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 80922.3
        )
    }
}
