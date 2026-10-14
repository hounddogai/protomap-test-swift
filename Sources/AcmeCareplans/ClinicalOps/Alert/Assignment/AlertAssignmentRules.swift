import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert assignment must pass. Check returns its problems, or none.
    protocol AlertAssignmentRule {
        func check(_ item: AlertAssignment) -> [String]
    }

    final class AlertAssignmentRequiredSpecialtyRule: AlertAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertAssignment) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertAssignmentClinicianIDLengthRule: AlertAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertAssignment) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertAssignmentCeilingRangeRule: AlertAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertAssignment) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AlertAssignmentSpecialtyLengthRule: AlertAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertAssignment) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert assignment.
    final class AlertAssignmentValidator {
        var rules: [any AlertAssignmentRule]

        init(rules: [any AlertAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertAssignment]) -> [String: [String]] {
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

    static func defaultAlertAssignmentValidator() -> AlertAssignmentValidator {
        return AlertAssignmentValidator(
            rules: [
                AlertAssignmentRequiredSpecialtyRule(message: "alert assignment needs a value"),
                AlertAssignmentClinicianIDLengthRule(maxLength: 1000),
                AlertAssignmentCeilingRangeRule(min: 6.6, max: 3487.3),
                AlertAssignmentSpecialtyLengthRule(maxLength: 255),
            ]
        )
    }
}
