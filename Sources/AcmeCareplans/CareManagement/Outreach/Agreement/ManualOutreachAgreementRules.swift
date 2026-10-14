import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual outreach agreement must pass. Check returns its problems, or none.
    protocol ManualOutreachAgreementRule {
        func check(_ item: ManualOutreachAgreement) -> [String]
    }

    final class ManualOutreachAgreementRequiredProcedureCodeRule: ManualOutreachAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualOutreachAgreement) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualOutreachAgreementRequiredTitleRule: ManualOutreachAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualOutreachAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualOutreachAgreementProcedureCodeLengthRule: ManualOutreachAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualOutreachAgreement) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualOutreachAgreementWindowDaysRangeRule: ManualOutreachAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualOutreachAgreement) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual outreach agreement.
    final class ManualOutreachAgreementValidator {
        var rules: [any ManualOutreachAgreementRule]

        init(rules: [any ManualOutreachAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualOutreachAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualOutreachAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualOutreachAgreement]) -> [String: [String]] {
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

    static func defaultManualOutreachAgreementValidator() -> ManualOutreachAgreementValidator {
        return ManualOutreachAgreementValidator(
            rules: [
                ManualOutreachAgreementRequiredProcedureCodeRule(
                    message: "manual outreach agreement needs this field"
                ),
                ManualOutreachAgreementRequiredTitleRule(message: "manual outreach agreement needs a value"),
                ManualOutreachAgreementProcedureCodeLengthRule(maxLength: 16),
                ManualOutreachAgreementWindowDaysRangeRule(min: 32, max: 120),
            ]
        )
    }
}
