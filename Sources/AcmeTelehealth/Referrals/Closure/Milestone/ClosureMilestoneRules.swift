import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure milestone must pass. Check returns its problems, or none.
    protocol ClosureMilestoneRule {
        func check(_ item: ClosureMilestone) -> [String]
    }

    final class ClosureMilestoneCodePrefixRule: ClosureMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClosureMilestoneRequiredTitleRule: ClosureMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureMilestoneCodeLengthRule: ClosureMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureMilestoneRequiredPayerRule: ClosureMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureMilestone) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureMilestoneScoreRangeRule: ClosureMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureMilestone) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a closure milestone.
    final class ClosureMilestoneValidator {
        var rules: [any ClosureMilestoneRule]

        init(rules: [any ClosureMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureMilestone]) -> [String: [String]] {
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

    static func defaultClosureMilestoneValidator() -> ClosureMilestoneValidator {
        return ClosureMilestoneValidator(
            rules: [
                ClosureMilestoneCodePrefixRule(prefix: "X"),
                ClosureMilestoneRequiredTitleRule(message: "closure milestone needs this field"),
                ClosureMilestoneCodeLengthRule(maxLength: 32),
                ClosureMilestoneRequiredPayerRule(message: "closure milestone needs this field"),
                ClosureMilestoneScoreRangeRule(min: 9.0, max: 2297.4),
            ]
        )
    }
}
