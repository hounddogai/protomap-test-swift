import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form agreement must pass. Check returns its problems, or none.
    protocol ConsentFormAgreementRule {
        func check(_ item: ConsentFormAgreement) -> [String]
    }

    final class ConsentFormAgreementRequiredPhoneRule: ConsentFormAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormAgreement) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormAgreementDurationMinutesRangeRule: ConsentFormAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormAgreement) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ConsentFormAgreementRequiredCountryRule: ConsentFormAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormAgreement) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormAgreementRequiredCodeRule: ConsentFormAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a consent form agreement.
    final class ConsentFormAgreementValidator {
        var rules: [any ConsentFormAgreementRule]

        init(rules: [any ConsentFormAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormAgreement]) -> [String: [String]] {
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

    static func defaultConsentFormAgreementValidator() -> ConsentFormAgreementValidator {
        return ConsentFormAgreementValidator(
            rules: [
                ConsentFormAgreementRequiredPhoneRule(message: "consent form agreement needs an entry"),
                ConsentFormAgreementDurationMinutesRangeRule(min: 32, max: 255),
                ConsentFormAgreementRequiredCountryRule(message: "consent form agreement needs this field"),
                ConsentFormAgreementRequiredCodeRule(message: "consent form agreement needs a value"),
            ]
        )
    }
}
