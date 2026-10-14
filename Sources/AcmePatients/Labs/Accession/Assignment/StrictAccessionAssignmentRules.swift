import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict accession assignment must pass. Check returns its problems, or none.
    protocol StrictAccessionAssignmentRule {
        func check(_ item: StrictAccessionAssignment) -> [String]
    }

    final class StrictAccessionAssignmentRequiredCodeRule: StrictAccessionAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAccessionAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictAccessionAssignmentRequiredNotesRule: StrictAccessionAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictAccessionAssignment) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictAccessionAssignmentAmountRangeRule: StrictAccessionAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictAccessionAssignment) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a strict accession assignment.
    final class StrictAccessionAssignmentValidator {
        var rules: [any StrictAccessionAssignmentRule]

        init(rules: [any StrictAccessionAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictAccessionAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictAccessionAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictAccessionAssignment]) -> [String: [String]] {
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

    static func defaultStrictAccessionAssignmentValidator() -> StrictAccessionAssignmentValidator {
        return StrictAccessionAssignmentValidator(
            rules: [
                StrictAccessionAssignmentRequiredCodeRule(message: "strict accession assignment needs this field"),
                StrictAccessionAssignmentRequiredNotesRule(message: "strict accession assignment needs an entry"),
                StrictAccessionAssignmentAmountRangeRule(min: 8.9, max: 4532.7),
            ]
        )
    }
}
