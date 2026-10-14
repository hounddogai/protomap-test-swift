import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched denial milestone must pass. Check returns its problems, or none.
    protocol BatchedDenialMilestoneRule {
        func check(_ item: BatchedDenialMilestone) -> [String]
    }

    final class BatchedDenialMilestoneCodePrefixRule: BatchedDenialMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedDenialMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedDenialMilestoneCodeLengthRule: BatchedDenialMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDenialMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDenialMilestoneRequiredTimezoneRule: BatchedDenialMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDenialMilestone) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched denial milestone.
    final class BatchedDenialMilestoneValidator {
        var rules: [any BatchedDenialMilestoneRule]

        init(rules: [any BatchedDenialMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDenialMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedDenialMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDenialMilestone]) -> [String: [String]] {
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

    static func defaultBatchedDenialMilestoneValidator() -> BatchedDenialMilestoneValidator {
        return BatchedDenialMilestoneValidator(
            rules: [
                BatchedDenialMilestoneCodePrefixRule(prefix: "REF"),
                BatchedDenialMilestoneCodeLengthRule(maxLength: 120),
                BatchedDenialMilestoneRequiredTimezoneRule(message: "batched denial milestone needs this field"),
            ]
        )
    }
}
