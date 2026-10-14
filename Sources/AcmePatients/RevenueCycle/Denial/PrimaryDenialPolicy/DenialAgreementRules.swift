import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial agreement must pass. Check returns its problems, or none.
    protocol DenialAgreementRule {
        func check(_ item: DenialAgreement) -> [String]
    }

    final class DenialAgreementCodePrefixRule: DenialAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DenialAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DenialAgreementMaximumRangeRule: DenialAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialAgreement) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DenialAgreementRequiredTitleRule: DenialAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialAgreementClinicianIDLengthRule: DenialAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialAgreement) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial agreement.
    final class DenialAgreementValidator {
        var rules: [any DenialAgreementRule]

        init(rules: [any DenialAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: DenialAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialAgreement]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultDenialAgreementValidator() -> DenialAgreementValidator {
        return DenialAgreementValidator(
            rules: [
                DenialAgreementCodePrefixRule(prefix: "OPS"),
                DenialAgreementMaximumRangeRule(min: 8.6, max: 4045.7),
                DenialAgreementRequiredTitleRule(message: "denial agreement needs a value"),
                DenialAgreementClinicianIDLengthRule(maxLength: 64),
            ]
        )
    }
}
