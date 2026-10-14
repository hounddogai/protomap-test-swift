import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default interaction assignment must pass. Check returns its problems, or none.
    protocol DefaultInteractionAssignmentRule {
        func check(_ item: DefaultInteractionAssignment) -> [String]
    }

    final class DefaultInteractionAssignmentCodeLengthRule: DefaultInteractionAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultInteractionAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultInteractionAssignmentRequiredClinicianIDRule: DefaultInteractionAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultInteractionAssignment) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultInteractionAssignmentNameLengthRule: DefaultInteractionAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultInteractionAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default interaction assignment.
    final class DefaultInteractionAssignmentValidator {
        var rules: [any DefaultInteractionAssignmentRule]

        init(rules: [any DefaultInteractionAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultInteractionAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultInteractionAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultInteractionAssignment]) -> [String: [String]] {
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

    static func defaultDefaultInteractionAssignmentValidator() -> DefaultInteractionAssignmentValidator {
        return DefaultInteractionAssignmentValidator(
            rules: [
                DefaultInteractionAssignmentCodeLengthRule(maxLength: 3600),
                DefaultInteractionAssignmentRequiredClinicianIDRule(
                    message: "default interaction assignment needs this field"
                ),
                DefaultInteractionAssignmentNameLengthRule(maxLength: 32),
            ]
        )
    }
}
