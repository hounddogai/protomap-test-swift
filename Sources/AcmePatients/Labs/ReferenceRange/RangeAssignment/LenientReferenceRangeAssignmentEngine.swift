import AcmePlatform
import Foundation

extension Labs {
    /// One step of the lenient reference range assignment calculation.
    protocol LenientReferenceRangeAssignmentFactor {
        func describe() -> String
        func adjust(_ item: LenientReferenceRangeAssignment, value: Double) -> Double
    }

    final class MinimumLenientReferenceRangeAssignmentAdjuster: LenientReferenceRangeAssignmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientReferenceRangeAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLenientReferenceRangeAssignmentAdjuster: LenientReferenceRangeAssignmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientReferenceRangeAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LenientReferenceRangeAssignmentCapacityOffsetAdjuster: LenientReferenceRangeAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: LenientReferenceRangeAssignment, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class FlaggedLenientReferenceRangeAssignmentAdjuster: LenientReferenceRangeAssignmentFactor {
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

        func adjust(_ item: LenientReferenceRangeAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientReferenceRangeAssignmentAdjuster: LenientReferenceRangeAssignmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientReferenceRangeAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelLenientReferenceRangeAssignmentAdjuster: LenientReferenceRangeAssignmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientReferenceRangeAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient reference range assignment steps in order and keeps a trace of each.
    final class LenientReferenceRangeAssignmentEngine {
        var steps: [any LenientReferenceRangeAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientReferenceRangeAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientReferenceRangeAssignment) -> Double {
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

        func evaluateAll(_ items: [LenientReferenceRangeAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientReferenceRangeAssignmentEngine(_ flags: Kit.Flags.Registry) -> LenientReferenceRangeAssignmentEngine {
        return LenientReferenceRangeAssignmentEngine(
            steps: [
                MinimumLenientReferenceRangeAssignmentAdjuster(minimum: 45.7),
                CapLenientReferenceRangeAssignmentAdjuster(cap: 8879.0),
                LenientReferenceRangeAssignmentCapacityOffsetAdjuster(weight: 1.34),
                FlaggedLenientReferenceRangeAssignmentAdjuster(
                    flags: flags,
                    flag: "lenient-reference-range-assignment-capped",
                    percent: 0.1
                ),
                RoundingLenientReferenceRangeAssignmentAdjuster(step: 0.25),
                LabelLenientReferenceRangeAssignmentAdjuster(factors: ["online": 0.75, "east": 1.33, "central": 1.08]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 55997.9
        )
    }
}
