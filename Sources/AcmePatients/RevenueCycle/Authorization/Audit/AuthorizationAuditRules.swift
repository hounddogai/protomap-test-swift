import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization audit must pass. Check returns its problems, or none.
    protocol AuthorizationAuditRule {
        func check(_ item: AuthorizationAudit) -> [String]
    }

    final class AuthorizationAuditTagsLimitRule: AuthorizationAuditRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: AuthorizationAudit) -> [String] {
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

    final class AuthorizationAuditCodePrefixRule: AuthorizationAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationAuditSequenceRangeRule: AuthorizationAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationAudit) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a authorization audit.
    final class AuthorizationAuditValidator {
        var rules: [any AuthorizationAuditRule]

        init(rules: [any AuthorizationAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationAudit) -> [String] {
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

        func requireValid(_ item: AuthorizationAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationAudit]) -> [String: [String]] {
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

    static func defaultAuthorizationAuditValidator() -> AuthorizationAuditValidator {
        return AuthorizationAuditValidator(
            rules: [
                AuthorizationAuditTagsLimitRule(maxCount: 80, banned: ["scheduled", "default"]),
                AuthorizationAuditCodePrefixRule(prefix: "X"),
                AuthorizationAuditSequenceRangeRule(min: 32, max: 64),
            ]
        )
    }
}
