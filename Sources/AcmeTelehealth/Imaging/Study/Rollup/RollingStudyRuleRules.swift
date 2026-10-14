import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling study rule must pass. Check returns its problems, or none.
    protocol RollingStudyRuleRule {
        func check(_ item: RollingStudyRule) -> [String]
    }

    final class RollingStudyRuleNameLengthRule: RollingStudyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingStudyRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingStudyRuleRetriesRangeRule: RollingStudyRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingStudyRule) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingStudyRuleCodePrefixRule: RollingStudyRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingStudyRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingStudyRuleAllowedNameRule: RollingStudyRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingStudyRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling study rule.
    final class RollingStudyRuleValidator {
        var rules: [any RollingStudyRuleRule]

        init(rules: [any RollingStudyRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingStudyRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingStudyRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingStudyRule]) -> [String: [String]] {
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

    static func defaultRollingStudyRuleValidator() -> RollingStudyRuleValidator {
        return RollingStudyRuleValidator(
            rules: [
                RollingStudyRuleNameLengthRule(maxLength: 86400),
                RollingStudyRuleRetriesRangeRule(min: 120, max: 1000),
                RollingStudyRuleCodePrefixRule(prefix: "X"),
                RollingStudyRuleAllowedNameRule(allowed: ["regional", "adaptive", "pending"]),
            ]
        )
    }
}
