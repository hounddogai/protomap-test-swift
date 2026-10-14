import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment record must pass. Check returns its problems, or none.
    protocol AssessmentRecordRule {
        func check(_ item: AssessmentRecord) -> [String]
    }

    final class AssessmentRecordCodeLengthRule: AssessmentRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentRecordRequiredTitleRule: AssessmentRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentRecord) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentRecordTitleLengthRule: AssessmentRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment record.
    final class AssessmentRecordValidator {
        var rules: [any AssessmentRecordRule]

        init(rules: [any AssessmentRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentRecord) -> [String] {
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

        func requireValid(_ item: AssessmentRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentRecord]) -> [String: [String]] {
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

    static func defaultAssessmentRecordValidator() -> AssessmentRecordValidator {
        return AssessmentRecordValidator(
            rules: [
                AssessmentRecordCodeLengthRule(maxLength: 86400),
                AssessmentRecordRequiredTitleRule(message: "assessment record needs this field"),
                AssessmentRecordTitleLengthRule(maxLength: 32),
            ]
        )
    }
}
