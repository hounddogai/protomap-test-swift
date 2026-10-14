import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution assignment must pass. Check returns its problems, or none.
    protocol SubstitutionAssignmentRule {
        func check(_ item: SubstitutionAssignment) -> [String]
    }

    final class SubstitutionAssignmentAllowedTitleRule: SubstitutionAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SubstitutionAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    final class SubstitutionAssignmentRateRangeRule: SubstitutionAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionAssignment) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SubstitutionAssignmentUnitLengthRule: SubstitutionAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionAssignment) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution assignment.
    final class SubstitutionAssignmentValidator {
        var rules: [any SubstitutionAssignmentRule]

        init(rules: [any SubstitutionAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionAssignment) -> [String] {
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

        func requireValid(_ item: SubstitutionAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionAssignment]) -> [String: [String]] {
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

    static func defaultSubstitutionAssignmentValidator() -> SubstitutionAssignmentValidator {
        return SubstitutionAssignmentValidator(
            rules: [
                SubstitutionAssignmentAllowedTitleRule(allowed: ["regional"]),
                SubstitutionAssignmentRateRangeRule(min: 2.1, max: 3439.0),
                SubstitutionAssignmentUnitLengthRule(maxLength: 3600),
            ]
        )
    }
}
