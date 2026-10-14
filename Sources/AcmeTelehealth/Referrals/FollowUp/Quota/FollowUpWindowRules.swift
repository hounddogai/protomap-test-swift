import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up window must pass. Check returns its problems, or none.
    protocol FollowUpWindowRule {
        func check(_ item: FollowUpWindow) -> [String]
    }

    final class FollowUpWindowRetriesRangeRule: FollowUpWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpWindow) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpWindowAllowedCodeRule: FollowUpWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FollowUpWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class FollowUpWindowCodeLengthRule: FollowUpWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpWindowRequiredPayerRule: FollowUpWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpWindow) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpWindowPriorityRangeRule: FollowUpWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpWindow) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up window.
    final class FollowUpWindowValidator {
        var rules: [any FollowUpWindowRule]

        init(rules: [any FollowUpWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpWindow]) -> [String: [String]] {
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

    static func defaultFollowUpWindowValidator() -> FollowUpWindowValidator {
        return FollowUpWindowValidator(
            rules: [
                FollowUpWindowRetriesRangeRule(min: 16, max: 64),
                FollowUpWindowAllowedCodeRule(allowed: ["global", "capped", "rolling"]),
                FollowUpWindowCodeLengthRule(maxLength: 16),
                FollowUpWindowRequiredPayerRule(message: "follow up window needs an entry"),
                FollowUpWindowPriorityRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
