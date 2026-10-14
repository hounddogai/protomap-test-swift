import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the lenient overtime assignment calculation.
    protocol LenientOvertimeAssignmentModifier {
        func describe() -> String
        func adjust(_ item: LenientOvertimeAssignment, value: Double) -> Double
    }

    final class LenientOvertimeAssignmentRefillsOffsetAdjuster: LenientOvertimeAssignmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: LenientOvertimeAssignment, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class TitleLenientOvertimeAssignmentAdjuster: LenientOvertimeAssignmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientOvertimeAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapLenientOvertimeAssignmentAdjuster: LenientOvertimeAssignmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientOvertimeAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLenientOvertimeAssignmentAdjuster: LenientOvertimeAssignmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientOvertimeAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLenientOvertimeAssignmentAdjuster: LenientOvertimeAssignmentModifier {
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

        func adjust(_ item: LenientOvertimeAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientOvertimeAssignmentAdjuster: LenientOvertimeAssignmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientOvertimeAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient overtime assignment steps in order and keeps a trace of each.
    final class LenientOvertimeAssignmentEngine {
        var steps: [any LenientOvertimeAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientOvertimeAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientOvertimeAssignment) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [LenientOvertimeAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientOvertimeAssignmentEngine(_ flags: Kit.Flags.Registry) -> LenientOvertimeAssignmentEngine {
        return LenientOvertimeAssignmentEngine(
            steps: [
                LenientOvertimeAssignmentRefillsOffsetAdjuster(weight: 1.93),
                TitleLenientOvertimeAssignmentAdjuster(factors: ["retail": 1.37, "west": 0.91]),
                CapLenientOvertimeAssignmentAdjuster(cap: 28608.0),
                MinimumLenientOvertimeAssignmentAdjuster(minimum: 49.5),
                FlaggedLenientOvertimeAssignmentAdjuster(
                    flags: flags,
                    flag: "lenient-overtime-assignment-weighted",
                    percent: 0.4
                ),
                RoundingLenientOvertimeAssignmentAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 66001.2
        )
    }
}
