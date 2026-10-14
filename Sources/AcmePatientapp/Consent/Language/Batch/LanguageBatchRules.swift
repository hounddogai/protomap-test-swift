import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language batch must pass. Check returns its problems, or none.
    protocol LanguageBatchRule {
        func check(_ item: LanguageBatch) -> [String]
    }

    final class LanguageBatchTitleLengthRule: LanguageBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageBatchRequiredPhoneRule: LanguageBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageBatch) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageBatchStartsAtRangeRule: LanguageBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageBatch) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguageBatchRequiredCategoryRule: LanguageBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageBatch) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageBatchCodePrefixRule: LanguageBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LanguageBatchCodeLengthRule: LanguageBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a language batch.
    final class LanguageBatchValidator {
        var rules: [any LanguageBatchRule]

        init(rules: [any LanguageBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageBatch) -> [String] {
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

        func requireValid(_ item: LanguageBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageBatch]) -> [String: [String]] {
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

    static func defaultLanguageBatchValidator() -> LanguageBatchValidator {
        return LanguageBatchValidator(
            rules: [
                LanguageBatchTitleLengthRule(maxLength: 64),
                LanguageBatchRequiredPhoneRule(message: "language batch needs an entry"),
                LanguageBatchStartsAtRangeRule(min: 1000, max: 86400),
                LanguageBatchRequiredCategoryRule(message: "language batch needs this field"),
                LanguageBatchCodePrefixRule(prefix: "ACM"),
                LanguageBatchCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
