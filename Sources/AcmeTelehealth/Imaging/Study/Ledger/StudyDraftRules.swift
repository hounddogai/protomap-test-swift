import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study draft must pass. Check returns its problems, or none.
    protocol StudyDraftRule {
        func check(_ item: StudyDraft) -> [String]
    }

    final class StudyDraftRequiredNameRule: StudyDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyDraftAllowedCodeRule: StudyDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class StudyDraftRequiredUnitRule: StudyDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyDraft) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyDraftCodeLengthRule: StudyDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyDraftMaximumRangeRule: StudyDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyDraft) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a study draft.
    final class StudyDraftValidator {
        var rules: [any StudyDraftRule]

        init(rules: [any StudyDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyDraft) -> [String] {
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

        func requireValid(_ item: StudyDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyDraft]) -> [String: [String]] {
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

    static func defaultStudyDraftValidator() -> StudyDraftValidator {
        return StudyDraftValidator(
            rules: [
                StudyDraftRequiredNameRule(message: "study draft needs an entry"),
                StudyDraftAllowedCodeRule(allowed: ["global", "regional"]),
                StudyDraftRequiredUnitRule(message: "study draft needs this field"),
                StudyDraftCodeLengthRule(maxLength: 255),
                StudyDraftMaximumRangeRule(min: 4.0, max: 2822.6),
            ]
        )
    }
}
