import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual worklist agreement must pass. Check returns its problems, or none.
    protocol ManualWorklistAgreementRule {
        func check(_ item: ManualWorklistAgreement) -> [String]
    }

    final class ManualWorklistAgreementDurationMinutesRangeRule: ManualWorklistAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualWorklistAgreement) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualWorklistAgreementRequiredTitleRule: ManualWorklistAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualWorklistAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualWorklistAgreementTitleLengthRule: ManualWorklistAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualWorklistAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualWorklistAgreementCodeLengthRule: ManualWorklistAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualWorklistAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual worklist agreement.
    final class ManualWorklistAgreementValidator {
        var rules: [any ManualWorklistAgreementRule]

        init(rules: [any ManualWorklistAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualWorklistAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualWorklistAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualWorklistAgreement]) -> [String: [String]] {
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

    static func defaultManualWorklistAgreementValidator() -> ManualWorklistAgreementValidator {
        return ManualWorklistAgreementValidator(
            rules: [
                ManualWorklistAgreementDurationMinutesRangeRule(min: 64, max: 1000),
                ManualWorklistAgreementRequiredTitleRule(message: "manual worklist agreement needs a value"),
                ManualWorklistAgreementTitleLengthRule(maxLength: 255),
                ManualWorklistAgreementCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
