import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled outreach cycle must pass. Check returns its problems, or none.
    protocol ScheduledOutreachCycleRule {
        func check(_ item: ScheduledOutreachCycle) -> [String]
    }

    final class ScheduledOutreachCycleAllowedCodeRule: ScheduledOutreachCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledOutreachCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class ScheduledOutreachCycleCodePrefixRule: ScheduledOutreachCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledOutreachCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledOutreachCycleChannelLengthRule: ScheduledOutreachCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledOutreachCycle) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledOutreachCycleRequiredChannelRule: ScheduledOutreachCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledOutreachCycle) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledOutreachCycleLabelLengthRule: ScheduledOutreachCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledOutreachCycle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled outreach cycle.
    final class ScheduledOutreachCycleValidator {
        var rules: [any ScheduledOutreachCycleRule]

        init(rules: [any ScheduledOutreachCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledOutreachCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledOutreachCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledOutreachCycle]) -> [String: [String]] {
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

    static func defaultScheduledOutreachCycleValidator() -> ScheduledOutreachCycleValidator {
        return ScheduledOutreachCycleValidator(
            rules: [
                ScheduledOutreachCycleAllowedCodeRule(allowed: ["legacy", "adaptive"]),
                ScheduledOutreachCycleCodePrefixRule(prefix: "X"),
                ScheduledOutreachCycleChannelLengthRule(maxLength: 32),
                ScheduledOutreachCycleRequiredChannelRule(message: "scheduled outreach cycle needs an entry"),
                ScheduledOutreachCycleLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
