import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range assignment must pass. Check returns its problems, or none.
    protocol ReferenceRangeAssignmentRule {
        func check(_ item: ReferenceRangeAssignment) -> [String]
    }

    final class ReferenceRangeAssignmentRequiredCodeRule: ReferenceRangeAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeAssignmentStartsAtRangeRule: ReferenceRangeAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeAssignment) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeAssignmentCreatedAtRangeRule: ReferenceRangeAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeAssignment) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeAssignmentAllowedProcedureCodeRule: ReferenceRangeAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range assignment.
    final class ReferenceRangeAssignmentValidator {
        var rules: [any ReferenceRangeAssignmentRule]

        init(rules: [any ReferenceRangeAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeAssignment]) -> [String: [String]] {
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

    static func defaultReferenceRangeAssignmentValidator() -> ReferenceRangeAssignmentValidator {
        return ReferenceRangeAssignmentValidator(
            rules: [
                ReferenceRangeAssignmentRequiredCodeRule(message: "reference range assignment needs a value"),
                ReferenceRangeAssignmentStartsAtRangeRule(min: 255, max: 1000),
                ReferenceRangeAssignmentCreatedAtRangeRule(min: 80, max: 80),
                ReferenceRangeAssignmentAllowedProcedureCodeRule(allowed: ["default", "lenient"]),
            ]
        )
    }
}
