import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility assignment must pass. Check returns its problems, or none.
    protocol EligibilityAssignmentRule {
        func check(_ item: EligibilityAssignment) -> [String]
    }

    final class EligibilityAssignmentRequiredCategoryRule: EligibilityAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityAssignment) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityAssignmentFloorValueRangeRule: EligibilityAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityAssignment) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class EligibilityAssignmentCategoryLengthRule: EligibilityAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityAssignment) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityAssignmentRequiredNameRule: EligibilityAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityAssignmentRequiredCodeRule: EligibilityAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility assignment.
    final class EligibilityAssignmentValidator {
        var rules: [any EligibilityAssignmentRule]

        init(rules: [any EligibilityAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityAssignment]) -> [String: [String]] {
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

    static func defaultEligibilityAssignmentValidator() -> EligibilityAssignmentValidator {
        return EligibilityAssignmentValidator(
            rules: [
                EligibilityAssignmentRequiredCategoryRule(message: "eligibility assignment needs an entry"),
                EligibilityAssignmentFloorValueRangeRule(min: 0.8, max: 2888.5),
                EligibilityAssignmentCategoryLengthRule(maxLength: 32),
                EligibilityAssignmentRequiredNameRule(message: "eligibility assignment needs this field"),
                EligibilityAssignmentRequiredCodeRule(message: "eligibility assignment needs a value"),
            ]
        )
    }
}
