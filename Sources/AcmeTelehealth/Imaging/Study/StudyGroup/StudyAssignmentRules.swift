import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study assignment must pass. Check returns its problems, or none.
    protocol StudyAssignmentRule {
        func check(_ item: StudyAssignment) -> [String]
    }

    final class StudyAssignmentCodeLengthRule: StudyAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyAssignmentAllowedCodeRule: StudyAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class StudyAssignmentBatchSizeRangeRule: StudyAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyAssignment) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StudyAssignmentDiscountRangeRule: StudyAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyAssignment) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StudyAssignmentRequiredCodeRule: StudyAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyAssignmentRequiredNameRule: StudyAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a study assignment.
    final class StudyAssignmentValidator {
        var rules: [any StudyAssignmentRule]

        init(rules: [any StudyAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyAssignment) -> [String] {
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

        func requireValid(_ item: StudyAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyAssignment]) -> [String: [String]] {
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

    static func defaultStudyAssignmentValidator() -> StudyAssignmentValidator {
        return StudyAssignmentValidator(
            rules: [
                StudyAssignmentCodeLengthRule(maxLength: 1000),
                StudyAssignmentAllowedCodeRule(allowed: ["batched"]),
                StudyAssignmentBatchSizeRangeRule(min: 32, max: 86400),
                StudyAssignmentDiscountRangeRule(min: 5.3, max: 1971.9),
                StudyAssignmentRequiredCodeRule(message: "study assignment needs an entry"),
                StudyAssignmentRequiredNameRule(message: "study assignment needs a value"),
            ]
        )
    }
}
