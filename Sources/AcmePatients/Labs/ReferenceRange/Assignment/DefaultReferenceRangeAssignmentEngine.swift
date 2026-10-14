import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default reference range assignment calculation.
    protocol DefaultReferenceRangeAssignmentFactor {
        func describe() -> String
        func adjust(_ item: DefaultReferenceRangeAssignment, value: Double) -> Double
    }

    final class RoundingDefaultReferenceRangeAssignmentAdjuster: DefaultReferenceRangeAssignmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultReferenceRangeAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameDefaultReferenceRangeAssignmentAdjuster: DefaultReferenceRangeAssignmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DefaultReferenceRangeAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDefaultReferenceRangeAssignmentAdjuster: DefaultReferenceRangeAssignmentFactor {
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

        func adjust(_ item: DefaultReferenceRangeAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultReferenceRangeAssignmentAdjuster: DefaultReferenceRangeAssignmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultReferenceRangeAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class DefaultReferenceRangeAssignmentSequenceOffsetAdjuster: DefaultReferenceRangeAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: DefaultReferenceRangeAssignment, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the default reference range assignment steps in order and keeps a trace of each.
    final class DefaultReferenceRangeAssignmentEngine {
        var steps: [any DefaultReferenceRangeAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultReferenceRangeAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultReferenceRangeAssignment) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultReferenceRangeAssignmentFactor = steps[index]
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

        func evaluateAll(_ items: [DefaultReferenceRangeAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultReferenceRangeAssignmentEngine(_ flags: Kit.Flags.Registry) -> DefaultReferenceRangeAssignmentEngine {
        return DefaultReferenceRangeAssignmentEngine(
            steps: [
                RoundingDefaultReferenceRangeAssignmentAdjuster(step: 1.0),
                NameDefaultReferenceRangeAssignmentAdjuster(factors: ["west": 1.18]),
                FlaggedDefaultReferenceRangeAssignmentAdjuster(
                    flags: flags,
                    flag: "default-reference-range-assignment-pending",
                    percent: -6.7
                ),
                MinimumDefaultReferenceRangeAssignmentAdjuster(minimum: 10.3),
                DefaultReferenceRangeAssignmentSequenceOffsetAdjuster(weight: 1.45),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 54939.3
        )
    }
}
