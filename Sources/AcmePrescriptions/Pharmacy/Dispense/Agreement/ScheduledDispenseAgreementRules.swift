import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a scheduled dispense agreement must pass. Check returns its problems, or none.
    protocol ScheduledDispenseAgreementRule {
        func check(_ item: ScheduledDispenseAgreement) -> [String]
    }

    final class ScheduledDispenseAgreementRequiredReviewerRule: ScheduledDispenseAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledDispenseAgreement) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledDispenseAgreementAllergyLengthRule: ScheduledDispenseAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledDispenseAgreement) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledDispenseAgreementAllowedAllergyRule: ScheduledDispenseAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledDispenseAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is unknown"]
            }
            return []
        }
    }

    final class ScheduledDispenseAgreementRequiredTitleRule: ScheduledDispenseAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledDispenseAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled dispense agreement.
    final class ScheduledDispenseAgreementValidator {
        var rules: [any ScheduledDispenseAgreementRule]

        init(rules: [any ScheduledDispenseAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledDispenseAgreement) -> [String] {
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

        func requireValid(_ item: ScheduledDispenseAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledDispenseAgreement]) -> [String: [String]] {
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

    static func defaultScheduledDispenseAgreementValidator() -> ScheduledDispenseAgreementValidator {
        return ScheduledDispenseAgreementValidator(
            rules: [
                ScheduledDispenseAgreementRequiredReviewerRule(message: "scheduled dispense agreement needs an entry"),
                ScheduledDispenseAgreementAllergyLengthRule(maxLength: 3600),
                ScheduledDispenseAgreementAllowedAllergyRule(allowed: ["lenient", "pending", "batched"]),
                ScheduledDispenseAgreementRequiredTitleRule(message: "scheduled dispense agreement needs a value"),
            ]
        )
    }
}
