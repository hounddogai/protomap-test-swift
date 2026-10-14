import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program assignment must pass. Check returns its problems, or none.
    protocol ProgramAssignmentRule {
        func check(_ item: ProgramAssignment) -> [String]
    }

    final class ProgramAssignmentPayerLengthRule: ProgramAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramAssignment) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramAssignmentRequiredCodeRule: ProgramAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramAssignmentRequiredPayerRule: ProgramAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramAssignment) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramAssignmentRequiredTitleRule: ProgramAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramAssignmentTitleLengthRule: ProgramAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramAssignmentSequenceRangeRule: ProgramAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramAssignment) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a program assignment.
    final class ProgramAssignmentValidator {
        var rules: [any ProgramAssignmentRule]

        init(rules: [any ProgramAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramAssignment]) -> [String: [String]] {
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

    static func defaultProgramAssignmentValidator() -> ProgramAssignmentValidator {
        return ProgramAssignmentValidator(
            rules: [
                ProgramAssignmentPayerLengthRule(maxLength: 1000),
                ProgramAssignmentRequiredCodeRule(message: "program assignment needs an entry"),
                ProgramAssignmentRequiredPayerRule(message: "program assignment needs a value"),
                ProgramAssignmentRequiredTitleRule(message: "program assignment needs a value"),
                ProgramAssignmentTitleLengthRule(maxLength: 16),
                ProgramAssignmentSequenceRangeRule(min: 32, max: 120),
            ]
        )
    }
}
