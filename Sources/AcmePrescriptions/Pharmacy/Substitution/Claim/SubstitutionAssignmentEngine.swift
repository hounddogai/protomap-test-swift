import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution assignment calculation.
    protocol SubstitutionAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: SubstitutionAssignment, value: Double) -> Double
    }

    final class SubstitutionAssignmentDurationMinutesOffsetAdjuster: SubstitutionAssignmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: SubstitutionAssignment, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class TieredSubstitutionAssignmentAdjuster: SubstitutionAssignmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SubstitutionAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitSubstitutionAssignmentAdjuster: SubstitutionAssignmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: SubstitutionAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingSubstitutionAssignmentAdjuster: SubstitutionAssignmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SubstitutionAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedSubstitutionAssignmentAdjuster: SubstitutionAssignmentAdjuster {
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

        func adjust(_ item: SubstitutionAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the substitution assignment steps in order and keeps a trace of each.
    final class SubstitutionAssignmentEngine {
        var steps: [any SubstitutionAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SubstitutionAssignment) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [SubstitutionAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSubstitutionAssignmentEngine(_ flags: Kit.Flags.Registry) -> SubstitutionAssignmentEngine {
        return SubstitutionAssignmentEngine(
            steps: [
                SubstitutionAssignmentDurationMinutesOffsetAdjuster(weight: 1.55),
                TieredSubstitutionAssignmentAdjuster(bounds: [6105.0, 9009.0], rates: [1.15, 1.0]),
                UnitSubstitutionAssignmentAdjuster(factors: ["west": 0.98]),
                RoundingSubstitutionAssignmentAdjuster(step: 5.0),
                FlaggedSubstitutionAssignmentAdjuster(
                    flags: flags,
                    flag: "substitution-assignment-strict",
                    percent: 3.4
                ),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 99034.1
        )
    }
}
