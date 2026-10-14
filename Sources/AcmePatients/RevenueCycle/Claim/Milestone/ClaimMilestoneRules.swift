import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim milestone must pass. Check returns its problems, or none.
    protocol ClaimMilestoneRule {
        func check(_ item: ClaimMilestone) -> [String]
    }

    final class ClaimMilestoneRevisionRangeRule: ClaimMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimMilestone) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClaimMilestoneRequiredSummaryRule: ClaimMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimMilestone) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimMilestoneCreatedAtRangeRule: ClaimMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimMilestone) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimMilestoneAllowedSummaryRule: ClaimMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is too long"]
            }
            return []
        }
    }

    final class ClaimMilestoneSummaryLengthRule: ClaimMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimMilestone) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim milestone.
    final class ClaimMilestoneValidator {
        var rules: [any ClaimMilestoneRule]

        init(rules: [any ClaimMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimMilestone) -> [String] {
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

        func requireValid(_ item: ClaimMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimMilestone]) -> [String: [String]] {
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

    static func defaultClaimMilestoneValidator() -> ClaimMilestoneValidator {
        return ClaimMilestoneValidator(
            rules: [
                ClaimMilestoneRevisionRangeRule(min: 120, max: 1000),
                ClaimMilestoneRequiredSummaryRule(message: "claim milestone needs this field"),
                ClaimMilestoneCreatedAtRangeRule(min: 16, max: 1000),
                ClaimMilestoneAllowedSummaryRule(allowed: ["rolling"]),
                ClaimMilestoneSummaryLengthRule(maxLength: 32),
            ]
        )
    }
}
