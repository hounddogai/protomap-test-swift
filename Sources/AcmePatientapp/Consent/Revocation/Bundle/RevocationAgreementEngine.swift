import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation agreement calculation.
    protocol RevocationAgreementStep {
        func describe() -> String
        func adjust(_ item: RevocationAgreement, value: Double) -> Double
    }

    final class FlaggedRevocationAgreementAdjuster: RevocationAgreementStep {
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

        func adjust(_ item: RevocationAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RevocationAgreementVisitMinutesOffsetAdjuster: RevocationAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: RevocationAgreement, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class RoundingRevocationAgreementAdjuster: RevocationAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the revocation agreement steps in order and keeps a trace of each.
    final class RevocationAgreementEngine {
        var steps: [any RevocationAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RevocationAgreement) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RevocationAgreementStep = steps[index]
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

        func evaluateAll(_ items: [RevocationAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRevocationAgreementEngine(_ flags: Kit.Flags.Registry) -> RevocationAgreementEngine {
        return RevocationAgreementEngine(
            steps: [
                FlaggedRevocationAgreementAdjuster(flags: flags, flag: "revocation-agreement-strict", percent: 5.8),
                RevocationAgreementVisitMinutesOffsetAdjuster(weight: 0.92),
                RoundingRevocationAgreementAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 6504.6
        )
    }
}
