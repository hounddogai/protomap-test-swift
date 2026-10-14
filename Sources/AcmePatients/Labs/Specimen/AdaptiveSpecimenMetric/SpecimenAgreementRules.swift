import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen agreement must pass. Check returns its problems, or none.
    protocol SpecimenAgreementRule {
        func check(_ item: SpecimenAgreement) -> [String]
    }

    final class SpecimenAgreementCodeLengthRule: SpecimenAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenAgreementCodePrefixRule: SpecimenAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SpecimenAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SpecimenAgreementRequiredSpecialtyRule: SpecimenAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenAgreement) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a specimen agreement.
    final class SpecimenAgreementValidator {
        var rules: [any SpecimenAgreementRule]

        init(rules: [any SpecimenAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenAgreement]) -> [String: [String]] {
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

    static func defaultSpecimenAgreementValidator() -> SpecimenAgreementValidator {
        return SpecimenAgreementValidator(
            rules: [
                SpecimenAgreementCodeLengthRule(maxLength: 86400),
                SpecimenAgreementCodePrefixRule(prefix: "ACM"),
                SpecimenAgreementRequiredSpecialtyRule(message: "specimen agreement needs a value"),
            ]
        )
    }
}
