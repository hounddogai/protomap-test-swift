import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist score must pass. Check returns its problems, or none.
    protocol WorklistScoreRule {
        func check(_ item: WorklistScore) -> [String]
    }

    final class WorklistScoreAllowedTitleRule: WorklistScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WorklistScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class WorklistScoreBedLengthRule: WorklistScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistScore) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistScoreRequiredTitleRule: WorklistScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a worklist score.
    final class WorklistScoreValidator {
        var rules: [any WorklistScoreRule]

        init(rules: [any WorklistScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistScore) -> [String] {
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

        func requireValid(_ item: WorklistScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistScore]) -> [String: [String]] {
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

    static func defaultWorklistScoreValidator() -> WorklistScoreValidator {
        return WorklistScoreValidator(
            rules: [
                WorklistScoreAllowedTitleRule(allowed: []),
                WorklistScoreBedLengthRule(maxLength: 32),
                WorklistScoreRequiredTitleRule(message: "worklist score needs a value"),
            ]
        )
    }
}
