import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a scheduled denial baseline must pass. Check returns its problems, or none.
    protocol ScheduledDenialBaselineRule {
        func check(_ item: ScheduledDenialBaseline) -> [String]
    }

    final class ScheduledDenialBaselineAllowedWardRule: ScheduledDenialBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledDenialBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is out of range"]
            }
            return []
        }
    }

    final class ScheduledDenialBaselineRequiredWardRule: ScheduledDenialBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledDenialBaseline) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledDenialBaselineCodePrefixRule: ScheduledDenialBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledDenialBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledDenialBaselineRequiredNameRule: ScheduledDenialBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledDenialBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled denial baseline.
    final class ScheduledDenialBaselineValidator {
        var rules: [any ScheduledDenialBaselineRule]

        init(rules: [any ScheduledDenialBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledDenialBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledDenialBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledDenialBaseline]) -> [String: [String]] {
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

    static func defaultScheduledDenialBaselineValidator() -> ScheduledDenialBaselineValidator {
        return ScheduledDenialBaselineValidator(
            rules: [
                ScheduledDenialBaselineAllowedWardRule(allowed: []),
                ScheduledDenialBaselineRequiredWardRule(message: "scheduled denial baseline needs a value"),
                ScheduledDenialBaselineCodePrefixRule(prefix: "ACM"),
                ScheduledDenialBaselineRequiredNameRule(message: "scheduled denial baseline needs a value"),
            ]
        )
    }
}
