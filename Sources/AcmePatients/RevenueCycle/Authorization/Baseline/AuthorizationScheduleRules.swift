import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization schedule must pass. Check returns its problems, or none.
    protocol AuthorizationScheduleRule {
        func check(_ item: AuthorizationSchedule) -> [String]
    }

    final class AuthorizationScheduleCodeLengthRule: AuthorizationScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationScheduleBudgetRangeRule: AuthorizationScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationSchedule) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AuthorizationSchedulePinnedGuardRule: AuthorizationScheduleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: AuthorizationSchedule) -> [String] {
            if item.pinned && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class AuthorizationScheduleAllowedLabelRule: AuthorizationScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AuthorizationSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    final class AuthorizationScheduleCodePrefixRule: AuthorizationScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization schedule.
    final class AuthorizationScheduleValidator {
        var rules: [any AuthorizationScheduleRule]

        init(rules: [any AuthorizationScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationSchedule]) -> [String: [String]] {
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

    static func defaultAuthorizationScheduleValidator() -> AuthorizationScheduleValidator {
        return AuthorizationScheduleValidator(
            rules: [
                AuthorizationScheduleCodeLengthRule(maxLength: 32),
                AuthorizationScheduleBudgetRangeRule(min: 8.7, max: 733.0),
                AuthorizationSchedulePinnedGuardRule(limit: 2.9),
                AuthorizationScheduleAllowedLabelRule(allowed: ["strict", "rolling"]),
                AuthorizationScheduleCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
