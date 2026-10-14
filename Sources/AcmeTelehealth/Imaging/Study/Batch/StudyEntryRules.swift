import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study entry must pass. Check returns its problems, or none.
    protocol StudyEntryRule {
        func check(_ item: StudyEntry) -> [String]
    }

    final class StudyEntryCodePrefixRule: StudyEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StudyEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StudyEntryRequiredTitleRule: StudyEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyEntryTitleLengthRule: StudyEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyEntryNameLengthRule: StudyEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a study entry.
    final class StudyEntryValidator {
        var rules: [any StudyEntryRule]

        init(rules: [any StudyEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StudyEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyEntry]) -> [String: [String]] {
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

    static func defaultStudyEntryValidator() -> StudyEntryValidator {
        return StudyEntryValidator(
            rules: [
                StudyEntryCodePrefixRule(prefix: "X"),
                StudyEntryRequiredTitleRule(message: "study entry needs this field"),
                StudyEntryTitleLengthRule(maxLength: 16),
                StudyEntryNameLengthRule(maxLength: 32),
            ]
        )
    }
}
