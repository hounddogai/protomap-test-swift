import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result tier must pass. Check returns its problems, or none.
    protocol ResultTierRule {
        func check(_ item: ResultTier) -> [String]
    }

    final class ResultTierChannelLengthRule: ResultTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultTier) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultTierCodeLengthRule: ResultTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultTierRequiredChannelRule: ResultTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultTier) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultTierAllowedTimezoneRule: ResultTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ResultTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is blocked"]
            }
            return []
        }
    }

    final class ResultTierSpecialtyLengthRule: ResultTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultTier) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a result tier.
    final class ResultTierValidator {
        var rules: [any ResultTierRule]

        init(rules: [any ResultTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultTier]) -> [String: [String]] {
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

    static func defaultResultTierValidator() -> ResultTierValidator {
        return ResultTierValidator(
            rules: [
                ResultTierChannelLengthRule(maxLength: 32),
                ResultTierCodeLengthRule(maxLength: 16),
                ResultTierRequiredChannelRule(message: "result tier needs a value"),
                ResultTierAllowedTimezoneRule(allowed: ["default", "fallback", "capped"]),
                ResultTierSpecialtyLengthRule(maxLength: 64),
            ]
        )
    }
}
