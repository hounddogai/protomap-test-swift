import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution milestone must pass. Check returns its problems, or none.
    protocol SubstitutionMilestoneRule {
        func check(_ item: SubstitutionMilestone) -> [String]
    }

    final class SubstitutionMilestoneAcuityRangeRule: SubstitutionMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionMilestone) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SubstitutionMilestoneRequiredPhoneRule: SubstitutionMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionMilestone) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionMilestoneExpiresAtRangeRule: SubstitutionMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionMilestone) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SubstitutionMilestoneAttemptsRangeRule: SubstitutionMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionMilestone) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a substitution milestone.
    final class SubstitutionMilestoneValidator {
        var rules: [any SubstitutionMilestoneRule]

        init(rules: [any SubstitutionMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionMilestone) -> [String] {
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

        func requireValid(_ item: SubstitutionMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionMilestone]) -> [String: [String]] {
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

    static func defaultSubstitutionMilestoneValidator() -> SubstitutionMilestoneValidator {
        return SubstitutionMilestoneValidator(
            rules: [
                SubstitutionMilestoneAcuityRangeRule(min: 64, max: 120),
                SubstitutionMilestoneRequiredPhoneRule(message: "substitution milestone needs this field"),
                SubstitutionMilestoneExpiresAtRangeRule(min: 64, max: 86400),
                SubstitutionMilestoneAttemptsRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
