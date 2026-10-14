import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling proxy override must pass. Check returns its problems, or none.
    protocol RollingProxyOverrideRule {
        func check(_ item: RollingProxyOverride) -> [String]
    }

    final class RollingProxyOverrideVisitMinutesRangeRule: RollingProxyOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingProxyOverride) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingProxyOverrideCodePrefixRule: RollingProxyOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingProxyOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingProxyOverrideAllowedSummaryRule: RollingProxyOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingProxyOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling proxy override.
    final class RollingProxyOverrideValidator {
        var rules: [any RollingProxyOverrideRule]

        init(rules: [any RollingProxyOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingProxyOverride) -> [String] {
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

        func requireValid(_ item: RollingProxyOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingProxyOverride]) -> [String: [String]] {
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

    static func defaultRollingProxyOverrideValidator() -> RollingProxyOverrideValidator {
        return RollingProxyOverrideValidator(
            rules: [
                RollingProxyOverrideVisitMinutesRangeRule(min: 120, max: 86400),
                RollingProxyOverrideCodePrefixRule(prefix: "REF"),
                RollingProxyOverrideAllowedSummaryRule(allowed: ["adaptive", "default", "global"]),
            ]
        )
    }
}
