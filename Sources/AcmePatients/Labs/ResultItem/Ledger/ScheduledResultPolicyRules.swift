import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled result policy must pass. Check returns its problems, or none.
    protocol ScheduledResultPolicyRule {
        func check(_ item: ScheduledResultPolicy) -> [String]
    }

    final class ScheduledResultPolicyCodePrefixRule: ScheduledResultPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledResultPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledResultPolicyRequiredSourceRule: ScheduledResultPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledResultPolicy) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledResultPolicyAllowedSegmentRule: ScheduledResultPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledResultPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is out of range"]
            }
            return []
        }
    }

    final class ScheduledResultPolicyCodeLengthRule: ScheduledResultPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledResultPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled result policy.
    final class ScheduledResultPolicyValidator {
        var rules: [any ScheduledResultPolicyRule]

        init(rules: [any ScheduledResultPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledResultPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledResultPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledResultPolicy]) -> [String: [String]] {
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

    static func defaultScheduledResultPolicyValidator() -> ScheduledResultPolicyValidator {
        return ScheduledResultPolicyValidator(
            rules: [
                ScheduledResultPolicyCodePrefixRule(prefix: "ACM"),
                ScheduledResultPolicyRequiredSourceRule(message: "scheduled result policy needs this field"),
                ScheduledResultPolicyAllowedSegmentRule(allowed: ["fallback"]),
                ScheduledResultPolicyCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
