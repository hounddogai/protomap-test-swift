import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert agreement must pass. Check returns its problems, or none.
    protocol AlertAgreementRule {
        func check(_ item: AlertAgreement) -> [String]
    }

    final class AlertAgreementCodeLengthRule: AlertAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertAgreementRequiredNameRule: AlertAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertAgreementPriorityRangeRule: AlertAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertAgreement) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertAgreementCreatedAtRangeRule: AlertAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertAgreement) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertAgreementDiagnosisCodeLengthRule: AlertAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertAgreement) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert agreement.
    final class AlertAgreementValidator {
        var rules: [any AlertAgreementRule]

        init(rules: [any AlertAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertAgreement) -> [String] {
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

        func requireValid(_ item: AlertAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertAgreement]) -> [String: [String]] {
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

    static func defaultAlertAgreementValidator() -> AlertAgreementValidator {
        return AlertAgreementValidator(
            rules: [
                AlertAgreementCodeLengthRule(maxLength: 3600),
                AlertAgreementRequiredNameRule(message: "alert agreement needs this field"),
                AlertAgreementPriorityRangeRule(min: 1000, max: 86400),
                AlertAgreementCreatedAtRangeRule(min: 64, max: 3600),
                AlertAgreementDiagnosisCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
