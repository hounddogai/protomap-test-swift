import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary assignment must pass. Check returns its problems, or none.
    protocol FormularyAssignmentRule {
        func check(_ item: FormularyAssignment) -> [String]
    }

    final class FormularyAssignmentContactEmailLengthRule: FormularyAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyAssignment) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyAssignmentRequiredContactEmailRule: FormularyAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyAssignment) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyAssignmentNameLengthRule: FormularyAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary assignment.
    final class FormularyAssignmentValidator {
        var rules: [any FormularyAssignmentRule]

        init(rules: [any FormularyAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyAssignment]) -> [String: [String]] {
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

    static func defaultFormularyAssignmentValidator() -> FormularyAssignmentValidator {
        return FormularyAssignmentValidator(
            rules: [
                FormularyAssignmentContactEmailLengthRule(maxLength: 255),
                FormularyAssignmentRequiredContactEmailRule(message: "formulary assignment needs an entry"),
                FormularyAssignmentNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
