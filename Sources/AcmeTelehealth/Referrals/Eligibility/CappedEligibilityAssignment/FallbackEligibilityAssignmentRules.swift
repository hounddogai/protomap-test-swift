import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback eligibility assignment must pass. Check returns its problems, or none.
    protocol FallbackEligibilityAssignmentRule {
        func check(_ item: FallbackEligibilityAssignment) -> [String]
    }

    final class FallbackEligibilityAssignmentMaximumRangeRule: FallbackEligibilityAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackEligibilityAssignment) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackEligibilityAssignmentRequiredFacilityRule: FallbackEligibilityAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityAssignment) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackEligibilityAssignmentNameLengthRule: FallbackEligibilityAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackEligibilityAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback eligibility assignment.
    final class FallbackEligibilityAssignmentValidator {
        var rules: [any FallbackEligibilityAssignmentRule]

        init(rules: [any FallbackEligibilityAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackEligibilityAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackEligibilityAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackEligibilityAssignment]) -> [String: [String]] {
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

    static func defaultFallbackEligibilityAssignmentValidator() -> FallbackEligibilityAssignmentValidator {
        return FallbackEligibilityAssignmentValidator(
            rules: [
                FallbackEligibilityAssignmentMaximumRangeRule(min: 4.4, max: 4154.8),
                FallbackEligibilityAssignmentRequiredFacilityRule(
                    message: "fallback eligibility assignment needs an entry"
                ),
                FallbackEligibilityAssignmentNameLengthRule(maxLength: 64),
            ]
        )
    }
}
