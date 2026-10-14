import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a default alert agreement must pass. Check returns its problems, or none.
    protocol DefaultAlertAgreementRule {
        func check(_ item: DefaultAlertAgreement) -> [String]
    }

    final class DefaultAlertAgreementCodeLengthRule: DefaultAlertAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultAlertAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultAlertAgreementAmountRangeRule: DefaultAlertAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultAlertAgreement) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultAlertAgreementApprovedGuardRule: DefaultAlertAgreementRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DefaultAlertAgreement) -> [String] {
            if item.approved && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class DefaultAlertAgreementRequiredLabelRule: DefaultAlertAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAlertAgreement) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default alert agreement.
    final class DefaultAlertAgreementValidator {
        var rules: [any DefaultAlertAgreementRule]

        init(rules: [any DefaultAlertAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultAlertAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultAlertAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultAlertAgreement]) -> [String: [String]] {
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

    static func defaultDefaultAlertAgreementValidator() -> DefaultAlertAgreementValidator {
        return DefaultAlertAgreementValidator(
            rules: [
                DefaultAlertAgreementCodeLengthRule(maxLength: 64),
                DefaultAlertAgreementAmountRangeRule(min: 4.1, max: 3308.5),
                DefaultAlertAgreementApprovedGuardRule(limit: 5.7),
                DefaultAlertAgreementRequiredLabelRule(message: "default alert agreement needs a value"),
            ]
        )
    }
}
