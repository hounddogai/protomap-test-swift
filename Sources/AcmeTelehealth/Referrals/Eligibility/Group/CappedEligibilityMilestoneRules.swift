import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped eligibility milestone must pass. Check returns its problems, or none.
    protocol CappedEligibilityMilestoneRule {
        func check(_ item: CappedEligibilityMilestone) -> [String]
    }

    final class CappedEligibilityMilestoneRequiredUnitRule: CappedEligibilityMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedEligibilityMilestone) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedEligibilityMilestoneRequiredSourceRule: CappedEligibilityMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedEligibilityMilestone) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedEligibilityMilestoneCodePrefixRule: CappedEligibilityMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedEligibilityMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedEligibilityMilestoneSourceLengthRule: CappedEligibilityMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedEligibilityMilestone) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped eligibility milestone.
    final class CappedEligibilityMilestoneValidator {
        var rules: [any CappedEligibilityMilestoneRule]

        init(rules: [any CappedEligibilityMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedEligibilityMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedEligibilityMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedEligibilityMilestone]) -> [String: [String]] {
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

    static func defaultCappedEligibilityMilestoneValidator() -> CappedEligibilityMilestoneValidator {
        return CappedEligibilityMilestoneValidator(
            rules: [
                CappedEligibilityMilestoneRequiredUnitRule(message: "capped eligibility milestone needs a value"),
                CappedEligibilityMilestoneRequiredSourceRule(message: "capped eligibility milestone needs this field"),
                CappedEligibilityMilestoneCodePrefixRule(prefix: "Q"),
                CappedEligibilityMilestoneSourceLengthRule(maxLength: 16),
            ]
        )
    }
}
