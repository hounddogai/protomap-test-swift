import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language score must pass. Check returns its problems, or none.
    protocol LanguageScoreRule {
        func check(_ item: LanguageScore) -> [String]
    }

    final class LanguageScoreLabelLengthRule: LanguageScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageScore) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageScoreRequiredCodeRule: LanguageScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageScoreNameLengthRule: LanguageScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a language score.
    final class LanguageScoreValidator {
        var rules: [any LanguageScoreRule]

        init(rules: [any LanguageScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageScore]) -> [String: [String]] {
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

    static func defaultLanguageScoreValidator() -> LanguageScoreValidator {
        return LanguageScoreValidator(
            rules: [
                LanguageScoreLabelLengthRule(maxLength: 255),
                LanguageScoreRequiredCodeRule(message: "language score needs this field"),
                LanguageScoreNameLengthRule(maxLength: 16),
            ]
        )
    }
}
