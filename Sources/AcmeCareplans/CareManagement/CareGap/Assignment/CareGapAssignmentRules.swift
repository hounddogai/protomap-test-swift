import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap assignment must pass. Check returns its problems, or none.
    protocol CareGapAssignmentRule {
        func check(_ item: CareGapAssignment) -> [String]
    }

    final class CareGapAssignmentAllowedNameRule: CareGapAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    final class CareGapAssignmentRequiredNameRule: CareGapAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapAssignmentCodeLengthRule: CareGapAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapAssignmentProcedureCodeLengthRule: CareGapAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapAssignment) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapAssignmentBudgetRangeRule: CareGapAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapAssignment) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care gap assignment.
    final class CareGapAssignmentValidator {
        var rules: [any CareGapAssignmentRule]

        init(rules: [any CareGapAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapAssignment) -> [String] {
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

        func requireValid(_ item: CareGapAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapAssignment]) -> [String: [String]] {
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

    static func defaultCareGapAssignmentValidator() -> CareGapAssignmentValidator {
        return CareGapAssignmentValidator(
            rules: [
                CareGapAssignmentAllowedNameRule(allowed: ["manual", "rolling", "legacy"]),
                CareGapAssignmentRequiredNameRule(message: "care gap assignment needs this field"),
                CareGapAssignmentCodeLengthRule(maxLength: 64),
                CareGapAssignmentProcedureCodeLengthRule(maxLength: 255),
                CareGapAssignmentBudgetRangeRule(min: 9.6, max: 705.9),
            ]
        )
    }
}
