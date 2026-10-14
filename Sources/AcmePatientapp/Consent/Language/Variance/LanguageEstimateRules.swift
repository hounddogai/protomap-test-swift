import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language estimate must pass. Check returns its problems, or none.
    protocol LanguageEstimateRule {
        func check(_ item: LanguageEstimate) -> [String]
    }

    final class LanguageEstimateSourceLengthRule: LanguageEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageEstimate) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageEstimateRequiredTitleRule: LanguageEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageEstimateRequiredCodeRule: LanguageEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageEstimateRequiredSourceRule: LanguageEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageEstimate) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageEstimateCodeLengthRule: LanguageEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a language estimate.
    final class LanguageEstimateValidator {
        var rules: [any LanguageEstimateRule]

        init(rules: [any LanguageEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageEstimate]) -> [String: [String]] {
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

    static func defaultLanguageEstimateValidator() -> LanguageEstimateValidator {
        return LanguageEstimateValidator(
            rules: [
                LanguageEstimateSourceLengthRule(maxLength: 3600),
                LanguageEstimateRequiredTitleRule(message: "language estimate needs a value"),
                LanguageEstimateRequiredCodeRule(message: "language estimate needs a value"),
                LanguageEstimateRequiredSourceRule(message: "language estimate needs a value"),
                LanguageEstimateCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
