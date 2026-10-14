import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending eligibility assignment must pass. Check returns its problems, or none.
    protocol PendingEligibilityAssignmentRule {
        func check(_ item: PendingEligibilityAssignment) -> [String]
    }

    final class PendingEligibilityAssignmentRequiredCodeRule: PendingEligibilityAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingEligibilityAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingEligibilityAssignmentRequiredPatientRefRule: PendingEligibilityAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingEligibilityAssignment) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingEligibilityAssignmentTitleLengthRule: PendingEligibilityAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingEligibilityAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingEligibilityAssignmentRequiredTitleRule: PendingEligibilityAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingEligibilityAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending eligibility assignment.
    final class PendingEligibilityAssignmentValidator {
        var rules: [any PendingEligibilityAssignmentRule]

        init(rules: [any PendingEligibilityAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingEligibilityAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingEligibilityAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingEligibilityAssignment]) -> [String: [String]] {
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

    static func defaultPendingEligibilityAssignmentValidator() -> PendingEligibilityAssignmentValidator {
        return PendingEligibilityAssignmentValidator(
            rules: [
                PendingEligibilityAssignmentRequiredCodeRule(message: "pending eligibility assignment needs an entry"),
                PendingEligibilityAssignmentRequiredPatientRefRule(
                    message: "pending eligibility assignment needs a value"
                ),
                PendingEligibilityAssignmentTitleLengthRule(maxLength: 120),
                PendingEligibilityAssignmentRequiredTitleRule(
                    message: "pending eligibility assignment needs this field"
                ),
            ]
        )
    }
}
