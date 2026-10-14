import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning score must pass. Check returns its problems, or none.
    protocol CleaningScoreRule {
        func check(_ item: CleaningScore) -> [String]
    }

    final class CleaningScoreTitleLengthRule: CleaningScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningScoreRequiredSummaryRule: CleaningScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningScore) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningScoreCodeLengthRule: CleaningScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningScoreRequiredTitleRule: CleaningScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningScoreRequiredCodeRule: CleaningScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning score.
    final class CleaningScoreValidator {
        var rules: [any CleaningScoreRule]

        init(rules: [any CleaningScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningScore) -> [String] {
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

        func requireValid(_ item: CleaningScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningScore]) -> [String: [String]] {
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

    static func defaultCleaningScoreValidator() -> CleaningScoreValidator {
        return CleaningScoreValidator(
            rules: [
                CleaningScoreTitleLengthRule(maxLength: 3600),
                CleaningScoreRequiredSummaryRule(message: "cleaning score needs a value"),
                CleaningScoreCodeLengthRule(maxLength: 16),
                CleaningScoreRequiredTitleRule(message: "cleaning score needs this field"),
                CleaningScoreRequiredCodeRule(message: "cleaning score needs an entry"),
            ]
        )
    }
}
