import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling isolation assignment must pass. Check returns its problems, or none.
    protocol RollingIsolationAssignmentRule {
        func check(_ item: RollingIsolationAssignment) -> [String]
    }

    final class RollingIsolationAssignmentDosageMgRangeRule: RollingIsolationAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingIsolationAssignment) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingIsolationAssignmentRequiredOwnerIDRule: RollingIsolationAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingIsolationAssignment) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingIsolationAssignmentRequiredNameRule: RollingIsolationAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingIsolationAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingIsolationAssignmentNameLengthRule: RollingIsolationAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingIsolationAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling isolation assignment.
    final class RollingIsolationAssignmentValidator {
        var rules: [any RollingIsolationAssignmentRule]

        init(rules: [any RollingIsolationAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingIsolationAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingIsolationAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingIsolationAssignment]) -> [String: [String]] {
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

    static func defaultRollingIsolationAssignmentValidator() -> RollingIsolationAssignmentValidator {
        return RollingIsolationAssignmentValidator(
            rules: [
                RollingIsolationAssignmentDosageMgRangeRule(min: 2.1, max: 4439.0),
                RollingIsolationAssignmentRequiredOwnerIDRule(message: "rolling isolation assignment needs an entry"),
                RollingIsolationAssignmentRequiredNameRule(message: "rolling isolation assignment needs a value"),
                RollingIsolationAssignmentNameLengthRule(maxLength: 255),
            ]
        )
    }
}
