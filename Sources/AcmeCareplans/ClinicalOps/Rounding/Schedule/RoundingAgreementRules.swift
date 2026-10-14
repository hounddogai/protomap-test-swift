import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding agreement must pass. Check returns its problems, or none.
    protocol RoundingAgreementRule {
        func check(_ item: RoundingAgreement) -> [String]
    }

    final class RoundingAgreementCodeLengthRule: RoundingAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingAgreementRequiredSourceRule: RoundingAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingAgreement) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingAgreementRequiredLabelRule: RoundingAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingAgreement) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingAgreementDurationMinutesRangeRule: RoundingAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingAgreement) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingAgreementRequiredPayerRule: RoundingAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingAgreement) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rounding agreement.
    final class RoundingAgreementValidator {
        var rules: [any RoundingAgreementRule]

        init(rules: [any RoundingAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingAgreement) -> [String] {
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

        func requireValid(_ item: RoundingAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingAgreement]) -> [String: [String]] {
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

    static func defaultRoundingAgreementValidator() -> RoundingAgreementValidator {
        return RoundingAgreementValidator(
            rules: [
                RoundingAgreementCodeLengthRule(maxLength: 86400),
                RoundingAgreementRequiredSourceRule(message: "rounding agreement needs an entry"),
                RoundingAgreementRequiredLabelRule(message: "rounding agreement needs a value"),
                RoundingAgreementDurationMinutesRangeRule(min: 80, max: 1000),
                RoundingAgreementRequiredPayerRule(message: "rounding agreement needs this field"),
            ]
        )
    }
}
