import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a scheduled claim milestone must pass. Check returns its problems, or none.
    protocol ScheduledClaimMilestoneRule {
        func check(_ item: ScheduledClaimMilestone) -> [String]
    }

    final class ScheduledClaimMilestoneRequiredCodeRule: ScheduledClaimMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledClaimMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledClaimMilestoneCodePrefixRule: ScheduledClaimMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledClaimMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledClaimMilestoneAllowedCodeRule: ScheduledClaimMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledClaimMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class ScheduledClaimMilestoneNameLengthRule: ScheduledClaimMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledClaimMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled claim milestone.
    final class ScheduledClaimMilestoneValidator {
        var rules: [any ScheduledClaimMilestoneRule]

        init(rules: [any ScheduledClaimMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledClaimMilestone) -> [String] {
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

        func requireValid(_ item: ScheduledClaimMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledClaimMilestone]) -> [String: [String]] {
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

    static func defaultScheduledClaimMilestoneValidator() -> ScheduledClaimMilestoneValidator {
        return ScheduledClaimMilestoneValidator(
            rules: [
                ScheduledClaimMilestoneRequiredCodeRule(message: "scheduled claim milestone needs a value"),
                ScheduledClaimMilestoneCodePrefixRule(prefix: "Q"),
                ScheduledClaimMilestoneAllowedCodeRule(allowed: []),
                ScheduledClaimMilestoneNameLengthRule(maxLength: 64),
            ]
        )
    }
}
