import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary assignment calculation.
    protocol FormularyAssignmentFactor {
        func describe() -> String
        func adjust(_ item: FormularyAssignment, value: Double) -> Double
    }

    final class FormularyAssignmentAmountOffsetAdjuster: FormularyAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: FormularyAssignment, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class RoundingFormularyAssignmentAdjuster: FormularyAssignmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FormularyAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameFormularyAssignmentAdjuster: FormularyAssignmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FormularyAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentFormularyAssignmentAdjuster: FormularyAssignmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFormularyAssignmentAdjuster: FormularyAssignmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FormularyAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedFormularyAssignmentAdjuster: FormularyAssignmentFactor {
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

        func adjust(_ item: FormularyAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the formulary assignment steps in order and keeps a trace of each.
    final class FormularyAssignmentEngine {
        var steps: [any FormularyAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FormularyAssignment) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyAssignmentFactor = steps[index]
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

        func evaluateAll(_ items: [FormularyAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFormularyAssignmentEngine(_ flags: Kit.Flags.Registry) -> FormularyAssignmentEngine {
        return FormularyAssignmentEngine(
            steps: [
                FormularyAssignmentAmountOffsetAdjuster(weight: 1.46),
                RoundingFormularyAssignmentAdjuster(step: 1.0),
                NameFormularyAssignmentAdjuster(factors: ["west": 1.17]),
                PercentFormularyAssignmentAdjuster(percent: -13.5),
                MinimumFormularyAssignmentAdjuster(minimum: 7.7),
                FlaggedFormularyAssignmentAdjuster(flags: flags, flag: "formulary-assignment-fallback", percent: -5.2),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 6014.4
        )
    }
}
