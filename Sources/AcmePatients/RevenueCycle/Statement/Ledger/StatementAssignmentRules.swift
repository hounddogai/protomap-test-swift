import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement assignment must pass. Check returns its problems, or none.
    protocol StatementAssignmentRule {
        func check(_ item: StatementAssignment) -> [String]
    }

    final class StatementAssignmentAllergyLengthRule: StatementAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementAssignment) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementAssignmentRequiredCodeRule: StatementAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementAssignmentCeilingRangeRule: StatementAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementAssignment) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementAssignmentExpiresAtRangeRule: StatementAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementAssignment) -> [String] {
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

    final class StatementAssignmentTitleLengthRule: StatementAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement assignment.
    final class StatementAssignmentValidator {
        var rules: [any StatementAssignmentRule]

        init(rules: [any StatementAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementAssignment]) -> [String: [String]] {
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

    static func defaultStatementAssignmentValidator() -> StatementAssignmentValidator {
        return StatementAssignmentValidator(
            rules: [
                StatementAssignmentAllergyLengthRule(maxLength: 255),
                StatementAssignmentRequiredCodeRule(message: "statement assignment needs a value"),
                StatementAssignmentCeilingRangeRule(min: 6.0, max: 1838.4),
                StatementAssignmentExpiresAtRangeRule(min: 32, max: 3600),
                StatementAssignmentTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
