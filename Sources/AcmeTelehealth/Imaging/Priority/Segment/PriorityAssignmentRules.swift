import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority assignment must pass. Check returns its problems, or none.
    protocol PriorityAssignmentRule {
        func check(_ item: PriorityAssignment) -> [String]
    }

    final class PriorityAssignmentLabelLengthRule: PriorityAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityAssignment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityAssignmentActiveGuardRule: PriorityAssignmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PriorityAssignment) -> [String] {
            if item.active && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class PriorityAssignmentRequiredLabelRule: PriorityAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityAssignment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a priority assignment.
    final class PriorityAssignmentValidator {
        var rules: [any PriorityAssignmentRule]

        init(rules: [any PriorityAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityAssignment]) -> [String: [String]] {
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

    static func defaultPriorityAssignmentValidator() -> PriorityAssignmentValidator {
        return PriorityAssignmentValidator(
            rules: [
                PriorityAssignmentLabelLengthRule(maxLength: 120),
                PriorityAssignmentActiveGuardRule(limit: 64),
                PriorityAssignmentRequiredLabelRule(message: "priority assignment needs a value"),
            ]
        )
    }
}
