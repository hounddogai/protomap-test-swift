import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling witness assignment must pass. Check returns its problems, or none.
    protocol RollingWitnessAssignmentRule {
        func check(_ item: RollingWitnessAssignment) -> [String]
    }

    final class RollingWitnessAssignmentAttemptsRangeRule: RollingWitnessAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingWitnessAssignment) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingWitnessAssignmentRequiredTitleRule: RollingWitnessAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingWitnessAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingWitnessAssignmentLocaleLengthRule: RollingWitnessAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingWitnessAssignment) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingWitnessAssignmentRequiredDiagnosisCodeRule: RollingWitnessAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingWitnessAssignment) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingWitnessAssignmentCodeLengthRule: RollingWitnessAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingWitnessAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingWitnessAssignmentDiagnosisCodeLengthRule: RollingWitnessAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingWitnessAssignment) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling witness assignment.
    final class RollingWitnessAssignmentValidator {
        var rules: [any RollingWitnessAssignmentRule]

        init(rules: [any RollingWitnessAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingWitnessAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingWitnessAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingWitnessAssignment]) -> [String: [String]] {
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

    static func defaultRollingWitnessAssignmentValidator() -> RollingWitnessAssignmentValidator {
        return RollingWitnessAssignmentValidator(
            rules: [
                RollingWitnessAssignmentAttemptsRangeRule(min: 16, max: 32),
                RollingWitnessAssignmentRequiredTitleRule(message: "rolling witness assignment needs an entry"),
                RollingWitnessAssignmentLocaleLengthRule(maxLength: 32),
                RollingWitnessAssignmentRequiredDiagnosisCodeRule(
                    message: "rolling witness assignment needs an entry"
                ),
                RollingWitnessAssignmentCodeLengthRule(maxLength: 16),
                RollingWitnessAssignmentDiagnosisCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
