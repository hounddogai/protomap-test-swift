import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language exception must pass. Check returns its problems, or none.
    protocol LanguageExceptionRule {
        func check(_ item: LanguageException) -> [String]
    }

    final class LanguageExceptionRequiredTitleRule: LanguageExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageException) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageExceptionDurationMinutesRangeRule: LanguageExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageException) -> [String] {
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

    final class LanguageExceptionTitleLengthRule: LanguageExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageExceptionApprovedGuardRule: LanguageExceptionRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LanguageException) -> [String] {
            if item.approved && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class LanguageExceptionRequiredCodeRule: LanguageExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a language exception.
    final class LanguageExceptionValidator {
        var rules: [any LanguageExceptionRule]

        init(rules: [any LanguageExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageException]) -> [String: [String]] {
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

    static func defaultLanguageExceptionValidator() -> LanguageExceptionValidator {
        return LanguageExceptionValidator(
            rules: [
                LanguageExceptionRequiredTitleRule(message: "language exception needs an entry"),
                LanguageExceptionDurationMinutesRangeRule(min: 64, max: 1000),
                LanguageExceptionTitleLengthRule(maxLength: 32),
                LanguageExceptionApprovedGuardRule(limit: 86400),
                LanguageExceptionRequiredCodeRule(message: "language exception needs a value"),
            ]
        )
    }
}
