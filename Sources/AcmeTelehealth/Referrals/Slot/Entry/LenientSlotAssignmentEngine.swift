import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the lenient slot assignment calculation.
    protocol LenientSlotAssignmentStep {
        func describe() -> String
        func adjust(_ item: LenientSlotAssignment, value: Double) -> Double
    }

    final class FlaggedLenientSlotAssignmentAdjuster: LenientSlotAssignmentStep {
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

        func adjust(_ item: LenientSlotAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLenientSlotAssignmentAdjuster: LenientSlotAssignmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientSlotAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientSlotAssignmentAdjuster: LenientSlotAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientSlotAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LenientSlotAssignmentAttemptsOffsetAdjuster: LenientSlotAssignmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: LenientSlotAssignment, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class CapLenientSlotAssignmentAdjuster: LenientSlotAssignmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientSlotAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLenientSlotAssignmentAdjuster: LenientSlotAssignmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientSlotAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient slot assignment steps in order and keeps a trace of each.
    final class LenientSlotAssignmentEngine {
        var steps: [any LenientSlotAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientSlotAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientSlotAssignment) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientSlotAssignmentStep = steps[index]
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

        func evaluateAll(_ items: [LenientSlotAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientSlotAssignmentEngine(_ flags: Kit.Flags.Registry) -> LenientSlotAssignmentEngine {
        return LenientSlotAssignmentEngine(
            steps: [
                FlaggedLenientSlotAssignmentAdjuster(
                    flags: flags,
                    flag: "lenient-slot-assignment-fallback",
                    percent: 8.0
                ),
                PercentLenientSlotAssignmentAdjuster(percent: 17.2),
                TieredLenientSlotAssignmentAdjuster(bounds: [2556.0, 3427.0], rates: [0.9, 1.17]),
                LenientSlotAssignmentAttemptsOffsetAdjuster(weight: 1.75),
                CapLenientSlotAssignmentAdjuster(cap: 7805.0),
                RoundingLenientSlotAssignmentAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 61403.4
        )
    }
}
