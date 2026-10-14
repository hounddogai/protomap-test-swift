import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning rule must pass. Check returns its problems, or none.
    protocol CleaningRuleRule {
        func check(_ item: CleaningRule) -> [String]
    }

    final class CleaningRuleExpiresAtRangeRule: CleaningRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningRule) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CleaningRuleCodeLengthRule: CleaningRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningRuleRequiredNameRule: CleaningRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningRuleTagsLimitRule: CleaningRuleRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: CleaningRule) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class CleaningRuleLocaleLengthRule: CleaningRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningRule) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning rule.
    final class CleaningRuleValidator {
        var rules: [any CleaningRuleRule]

        init(rules: [any CleaningRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningRule]) -> [String: [String]] {
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

    static func defaultCleaningRuleValidator() -> CleaningRuleValidator {
        return CleaningRuleValidator(
            rules: [
                CleaningRuleExpiresAtRangeRule(min: 255, max: 3600),
                CleaningRuleCodeLengthRule(maxLength: 255),
                CleaningRuleRequiredNameRule(message: "cleaning rule needs a value"),
                CleaningRuleTagsLimitRule(maxCount: 86400, banned: ["fallback", "primary", "rolling"]),
                CleaningRuleLocaleLengthRule(maxLength: 255),
            ]
        )
    }
}
