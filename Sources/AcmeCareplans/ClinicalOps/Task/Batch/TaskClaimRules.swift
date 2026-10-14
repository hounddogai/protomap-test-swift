import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task claim must pass. Check returns its problems, or none.
    protocol TaskClaimRule {
        func check(_ item: TaskClaim) -> [String]
    }

    final class TaskClaimRequiredNameRule: TaskClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskClaim) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskClaimCapacityRangeRule: TaskClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskClaim) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskClaimQuantityRangeRule: TaskClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskClaim) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskClaimPatientRefLengthRule: TaskClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskClaim) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskClaimRequiredCodeRule: TaskClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task claim.
    final class TaskClaimValidator {
        var rules: [any TaskClaimRule]

        init(rules: [any TaskClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskClaim) -> [String] {
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

        func requireValid(_ item: TaskClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskClaim]) -> [String: [String]] {
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

    static func defaultTaskClaimValidator() -> TaskClaimValidator {
        return TaskClaimValidator(
            rules: [
                TaskClaimRequiredNameRule(message: "task claim needs this field"),
                TaskClaimCapacityRangeRule(min: 16, max: 120),
                TaskClaimQuantityRangeRule(min: 255, max: 86400),
                TaskClaimPatientRefLengthRule(maxLength: 64),
                TaskClaimRequiredCodeRule(message: "task claim needs a value"),
            ]
        )
    }
}
