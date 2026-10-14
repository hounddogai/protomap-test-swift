import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation assignment calculation.
    protocol RevocationAssignmentModifier {
        func describe() -> String
        func adjust(_ item: RevocationAssignment, value: Double) -> Double
    }

    final class MinimumRevocationAssignmentAdjuster: RevocationAssignmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityRevocationAssignmentAdjuster: RevocationAssignmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: RevocationAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRevocationAssignmentAdjuster: RevocationAssignmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRevocationAssignmentAdjuster: RevocationAssignmentModifier {
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

        func adjust(_ item: RevocationAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RevocationAssignmentCopayOffsetAdjuster: RevocationAssignmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: RevocationAssignment, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    /// Runs the revocation assignment steps in order and keeps a trace of each.
    final class RevocationAssignmentEngine {
        var steps: [any RevocationAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RevocationAssignment) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RevocationAssignmentModifier = steps[index]
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

        func evaluateAll(_ items: [RevocationAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRevocationAssignmentEngine(_ flags: Kit.Flags.Registry) -> RevocationAssignmentEngine {
        return RevocationAssignmentEngine(
            steps: [
                MinimumRevocationAssignmentAdjuster(minimum: 5.4),
                FacilityRevocationAssignmentAdjuster(factors: ["south": 1.0]),
                RoundingRevocationAssignmentAdjuster(step: 0.05),
                FlaggedRevocationAssignmentAdjuster(flags: flags, flag: "revocation-assignment-batched", percent: 8.5),
                RevocationAssignmentCopayOffsetAdjuster(weight: 0.46),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 26819.1
        )
    }
}
