import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution plan must pass. Check returns its problems, or none.
    protocol SubstitutionPlanRule {
        func check(_ item: SubstitutionPlan) -> [String]
    }

    final class SubstitutionPlanNameLengthRule: SubstitutionPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionPlan) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionPlanRequiredCodeRule: SubstitutionPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionPlanEndsAtRangeRule: SubstitutionPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionPlan) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a substitution plan.
    final class SubstitutionPlanValidator {
        var rules: [any SubstitutionPlanRule]

        init(rules: [any SubstitutionPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionPlan]) -> [String: [String]] {
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

    static func defaultSubstitutionPlanValidator() -> SubstitutionPlanValidator {
        return SubstitutionPlanValidator(
            rules: [
                SubstitutionPlanNameLengthRule(maxLength: 3600),
                SubstitutionPlanRequiredCodeRule(message: "substitution plan needs a value"),
                SubstitutionPlanEndsAtRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
