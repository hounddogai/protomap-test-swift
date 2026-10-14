import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual cleaning assignment must pass. Check returns its problems, or none.
    protocol ManualCleaningAssignmentRule {
        func check(_ item: ManualCleaningAssignment) -> [String]
    }

    final class ManualCleaningAssignmentAllowedContactEmailRule: ManualCleaningAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualCleaningAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is above maximum"]
            }
            return []
        }
    }

    final class ManualCleaningAssignmentBatchSizeRangeRule: ManualCleaningAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualCleaningAssignment) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualCleaningAssignmentRequiredCodeRule: ManualCleaningAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCleaningAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual cleaning assignment.
    final class ManualCleaningAssignmentValidator {
        var rules: [any ManualCleaningAssignmentRule]

        init(rules: [any ManualCleaningAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCleaningAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualCleaningAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCleaningAssignment]) -> [String: [String]] {
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

    static func defaultManualCleaningAssignmentValidator() -> ManualCleaningAssignmentValidator {
        return ManualCleaningAssignmentValidator(
            rules: [
                ManualCleaningAssignmentAllowedContactEmailRule(allowed: []),
                ManualCleaningAssignmentBatchSizeRangeRule(min: 32, max: 3600),
                ManualCleaningAssignmentRequiredCodeRule(message: "manual cleaning assignment needs this field"),
            ]
        )
    }
}
