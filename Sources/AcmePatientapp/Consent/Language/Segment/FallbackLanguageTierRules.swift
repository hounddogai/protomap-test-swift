import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback language tier must pass. Check returns its problems, or none.
    protocol FallbackLanguageTierRule {
        func check(_ item: FallbackLanguageTier) -> [String]
    }

    final class FallbackLanguageTierBudgetRangeRule: FallbackLanguageTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackLanguageTier) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackLanguageTierRequiredCodeRule: FallbackLanguageTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackLanguageTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackLanguageTierChannelLengthRule: FallbackLanguageTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackLanguageTier) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackLanguageTierRequiredCurrencyRule: FallbackLanguageTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackLanguageTier) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackLanguageTierCodeLengthRule: FallbackLanguageTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackLanguageTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback language tier.
    final class FallbackLanguageTierValidator {
        var rules: [any FallbackLanguageTierRule]

        init(rules: [any FallbackLanguageTierRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackLanguageTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackLanguageTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackLanguageTier]) -> [String: [String]] {
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

    static func defaultFallbackLanguageTierValidator() -> FallbackLanguageTierValidator {
        return FallbackLanguageTierValidator(
            rules: [
                FallbackLanguageTierBudgetRangeRule(min: 0.5, max: 1011.5),
                FallbackLanguageTierRequiredCodeRule(message: "fallback language tier needs this field"),
                FallbackLanguageTierChannelLengthRule(maxLength: 80),
                FallbackLanguageTierRequiredCurrencyRule(message: "fallback language tier needs a value"),
                FallbackLanguageTierCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
