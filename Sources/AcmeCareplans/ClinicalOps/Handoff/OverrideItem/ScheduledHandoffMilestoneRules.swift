import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled handoff milestone must pass. Check returns its problems, or none.
    protocol ScheduledHandoffMilestoneRule {
        func check(_ item: ScheduledHandoffMilestone) -> [String]
    }

    final class ScheduledHandoffMilestoneRequiredTimezoneRule: ScheduledHandoffMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledHandoffMilestone) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledHandoffMilestoneCodeLengthRule: ScheduledHandoffMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledHandoffMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledHandoffMilestoneCodePrefixRule: ScheduledHandoffMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledHandoffMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledHandoffMilestoneAllowedCodeRule: ScheduledHandoffMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledHandoffMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled handoff milestone.
    final class ScheduledHandoffMilestoneValidator {
        var rules: [any ScheduledHandoffMilestoneRule]

        init(rules: [any ScheduledHandoffMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledHandoffMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledHandoffMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledHandoffMilestone]) -> [String: [String]] {
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

    static func defaultScheduledHandoffMilestoneValidator() -> ScheduledHandoffMilestoneValidator {
        return ScheduledHandoffMilestoneValidator(
            rules: [
                ScheduledHandoffMilestoneRequiredTimezoneRule(message: "scheduled handoff milestone needs an entry"),
                ScheduledHandoffMilestoneCodeLengthRule(maxLength: 1000),
                ScheduledHandoffMilestoneCodePrefixRule(prefix: "OPS"),
                ScheduledHandoffMilestoneAllowedCodeRule(allowed: ["rolling", "global"]),
            ]
        )
    }
}
