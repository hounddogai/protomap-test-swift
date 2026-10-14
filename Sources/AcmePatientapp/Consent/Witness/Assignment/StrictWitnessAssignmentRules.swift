import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict witness assignment must pass. Check returns its problems, or none.
    protocol StrictWitnessAssignmentRule {
        func check(_ item: StrictWitnessAssignment) -> [String]
    }

    final class StrictWitnessAssignmentRequiredContactEmailRule: StrictWitnessAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWitnessAssignment) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictWitnessAssignmentRequiredTitleRule: StrictWitnessAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWitnessAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictWitnessAssignmentRequiredUnitRule: StrictWitnessAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWitnessAssignment) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict witness assignment.
    final class StrictWitnessAssignmentValidator {
        var rules: [any StrictWitnessAssignmentRule]

        init(rules: [any StrictWitnessAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictWitnessAssignment) -> [String] {
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

        func requireValid(_ item: StrictWitnessAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictWitnessAssignment]) -> [String: [String]] {
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

    static func defaultStrictWitnessAssignmentValidator() -> StrictWitnessAssignmentValidator {
        return StrictWitnessAssignmentValidator(
            rules: [
                StrictWitnessAssignmentRequiredContactEmailRule(message: "strict witness assignment needs this field"),
                StrictWitnessAssignmentRequiredTitleRule(message: "strict witness assignment needs a value"),
                StrictWitnessAssignmentRequiredUnitRule(message: "strict witness assignment needs a value"),
            ]
        )
    }
}
