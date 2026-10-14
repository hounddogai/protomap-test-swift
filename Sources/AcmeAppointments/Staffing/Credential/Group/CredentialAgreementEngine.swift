import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential agreement calculation.
    protocol CredentialAgreementModifier {
        func describe() -> String
        func adjust(_ item: CredentialAgreement, value: Double) -> Double
    }

    final class FlaggedCredentialAgreementAdjuster: CredentialAgreementModifier {
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

        func adjust(_ item: CredentialAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCredentialAgreementAdjuster: CredentialAgreementModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CredentialAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CategoryCredentialAgreementAdjuster: CredentialAgreementModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: CredentialAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCredentialAgreementAdjuster: CredentialAgreementModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the credential agreement steps in order and keeps a trace of each.
    final class CredentialAgreementEngine {
        var steps: [any CredentialAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CredentialAgreement) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CredentialAgreementModifier = steps[index]
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

        func evaluateAll(_ items: [CredentialAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCredentialAgreementEngine(_ flags: Kit.Flags.Registry) -> CredentialAgreementEngine {
        return CredentialAgreementEngine(
            steps: [
                FlaggedCredentialAgreementAdjuster(flags: flags, flag: "credential-agreement-scheduled", percent: 5.7),
                RoundingCredentialAgreementAdjuster(step: 0.25),
                CategoryCredentialAgreementAdjuster(factors: ["retail": 1.08, "north": 0.81, "east": 0.91]),
                CapCredentialAgreementAdjuster(cap: 32348.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 13728.2
        )
    }
}
