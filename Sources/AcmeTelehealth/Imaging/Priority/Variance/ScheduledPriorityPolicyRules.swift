import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled priority policy must pass. Check returns its problems, or none.
    protocol ScheduledPriorityPolicyRule {
        func check(_ item: ScheduledPriorityPolicy) -> [String]
    }

    final class ScheduledPriorityPolicyCodePrefixRule: ScheduledPriorityPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledPriorityPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledPriorityPolicyRequiredSourceRule: ScheduledPriorityPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPriorityPolicy) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledPriorityPolicySummaryLengthRule: ScheduledPriorityPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledPriorityPolicy) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledPriorityPolicyAllowedLabelRule: ScheduledPriorityPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledPriorityPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled priority policy.
    final class ScheduledPriorityPolicyValidator {
        var rules: [any ScheduledPriorityPolicyRule]

        init(rules: [any ScheduledPriorityPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledPriorityPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledPriorityPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledPriorityPolicy]) -> [String: [String]] {
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

    static func defaultScheduledPriorityPolicyValidator() -> ScheduledPriorityPolicyValidator {
        return ScheduledPriorityPolicyValidator(
            rules: [
                ScheduledPriorityPolicyCodePrefixRule(prefix: "X"),
                ScheduledPriorityPolicyRequiredSourceRule(message: "scheduled priority policy needs an entry"),
                ScheduledPriorityPolicySummaryLengthRule(maxLength: 3600),
                ScheduledPriorityPolicyAllowedLabelRule(allowed: ["tiered", "adaptive", "default"]),
            ]
        )
    }
}
