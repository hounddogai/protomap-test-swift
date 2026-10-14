import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient language agreement must pass. Check returns its problems, or none.
    protocol LenientLanguageAgreementRule {
        func check(_ item: LenientLanguageAgreement) -> [String]
    }

    final class LenientLanguageAgreementRequiredCodeRule: LenientLanguageAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientLanguageAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientLanguageAgreementTitleLengthRule: LenientLanguageAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientLanguageAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientLanguageAgreementRequiredDiagnosisCodeRule: LenientLanguageAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientLanguageAgreement) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientLanguageAgreementRequiredBedRule: LenientLanguageAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientLanguageAgreement) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient language agreement.
    final class LenientLanguageAgreementValidator {
        var rules: [any LenientLanguageAgreementRule]

        init(rules: [any LenientLanguageAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientLanguageAgreement) -> [String] {
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

        func requireValid(_ item: LenientLanguageAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientLanguageAgreement]) -> [String: [String]] {
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

    static func defaultLenientLanguageAgreementValidator() -> LenientLanguageAgreementValidator {
        return LenientLanguageAgreementValidator(
            rules: [
                LenientLanguageAgreementRequiredCodeRule(message: "lenient language agreement needs this field"),
                LenientLanguageAgreementTitleLengthRule(maxLength: 64),
                LenientLanguageAgreementRequiredDiagnosisCodeRule(message: "lenient language agreement needs a value"),
                LenientLanguageAgreementRequiredBedRule(message: "lenient language agreement needs an entry"),
            ]
        )
    }
}
