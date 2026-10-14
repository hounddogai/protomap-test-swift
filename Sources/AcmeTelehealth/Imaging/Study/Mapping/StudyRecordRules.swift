import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study record must pass. Check returns its problems, or none.
    protocol StudyRecordRule {
        func check(_ item: StudyRecord) -> [String]
    }

    final class StudyRecordContactEmailLengthRule: StudyRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyRecord) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyRecordBudgetRangeRule: StudyRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyRecord) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StudyRecordCategoryLengthRule: StudyRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyRecord) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a study record.
    final class StudyRecordValidator {
        var rules: [any StudyRecordRule]

        init(rules: [any StudyRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyRecord) -> [String] {
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

        func requireValid(_ item: StudyRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyRecord]) -> [String: [String]] {
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

    static func defaultStudyRecordValidator() -> StudyRecordValidator {
        return StudyRecordValidator(
            rules: [
                StudyRecordContactEmailLengthRule(maxLength: 32),
                StudyRecordBudgetRangeRule(min: 1.7, max: 125.7),
                StudyRecordCategoryLengthRule(maxLength: 86400),
            ]
        )
    }
}
