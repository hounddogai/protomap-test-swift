import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling risk score rule must pass. Check returns its problems, or none.
    protocol RollingRiskScoreRuleRule {
        func check(_ item: RollingRiskScoreRule) -> [String]
    }

    final class RollingRiskScoreRuleTagsLimitRule: RollingRiskScoreRuleRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RollingRiskScoreRule) -> [String] {
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

    final class RollingRiskScoreRuleRequiredCodeRule: RollingRiskScoreRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRiskScoreRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingRiskScoreRuleCodePrefixRule: RollingRiskScoreRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingRiskScoreRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingRiskScoreRuleCodeLengthRule: RollingRiskScoreRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRiskScoreRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling risk score rule.
    final class RollingRiskScoreRuleValidator {
        var rules: [any RollingRiskScoreRuleRule]

        init(rules: [any RollingRiskScoreRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRiskScoreRule) -> [String] {
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

        func requireValid(_ item: RollingRiskScoreRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRiskScoreRule]) -> [String: [String]] {
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

    static func defaultRollingRiskScoreRuleValidator() -> RollingRiskScoreRuleValidator {
        return RollingRiskScoreRuleValidator(
            rules: [
                RollingRiskScoreRuleTagsLimitRule(maxCount: 16, banned: ["weighted", "capped", "rolling"]),
                RollingRiskScoreRuleRequiredCodeRule(message: "rolling risk score rule needs an entry"),
                RollingRiskScoreRuleCodePrefixRule(prefix: "ACM"),
                RollingRiskScoreRuleCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
