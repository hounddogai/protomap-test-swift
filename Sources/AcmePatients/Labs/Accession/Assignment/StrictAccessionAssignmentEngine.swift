import AcmePlatform
import Foundation

extension Labs {
    /// One step of the strict accession assignment calculation.
    protocol StrictAccessionAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: StrictAccessionAssignment, value: Double) -> Double
    }

    final class FlaggedStrictAccessionAssignmentAdjuster: StrictAccessionAssignmentAdjuster {
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

        func adjust(_ item: StrictAccessionAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStrictAccessionAssignmentAdjuster: StrictAccessionAssignmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictAccessionAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class StrictAccessionAssignmentDosageMgOffsetAdjuster: StrictAccessionAssignmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: StrictAccessionAssignment, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class TitleStrictAccessionAssignmentAdjuster: StrictAccessionAssignmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: StrictAccessionAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the strict accession assignment steps in order and keeps a trace of each.
    final class StrictAccessionAssignmentEngine {
        var steps: [any StrictAccessionAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictAccessionAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictAccessionAssignment) -> Double {
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

        func evaluateAll(_ items: [StrictAccessionAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictAccessionAssignmentEngine(_ flags: Kit.Flags.Registry) -> StrictAccessionAssignmentEngine {
        return StrictAccessionAssignmentEngine(
            steps: [
                FlaggedStrictAccessionAssignmentAdjuster(
                    flags: flags,
                    flag: "strict-accession-assignment-regional",
                    percent: -7.3
                ),
                MinimumStrictAccessionAssignmentAdjuster(minimum: 30.4),
                StrictAccessionAssignmentDosageMgOffsetAdjuster(weight: 1.06),
                TitleStrictAccessionAssignmentAdjuster(factors: ["online": 0.96, "west": 1.01]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 70394.1
        )
    }
}
