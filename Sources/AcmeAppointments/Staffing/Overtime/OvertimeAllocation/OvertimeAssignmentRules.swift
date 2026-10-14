import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime assignment must pass. Check returns its problems, or none.
    protocol OvertimeAssignmentRule {
        func check(_ item: OvertimeAssignment) -> [String]
    }

    final class OvertimeAssignmentCodeLengthRule: OvertimeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeAssignmentRequiredNameRule: OvertimeAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeAssignmentAllowedNameRule: OvertimeAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OvertimeAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime assignment.
    final class OvertimeAssignmentValidator {
        var rules: [any OvertimeAssignmentRule]

        init(rules: [any OvertimeAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeAssignment]) -> [String: [String]] {
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

    static func defaultOvertimeAssignmentValidator() -> OvertimeAssignmentValidator {
        return OvertimeAssignmentValidator(
            rules: [
                OvertimeAssignmentCodeLengthRule(maxLength: 120),
                OvertimeAssignmentRequiredNameRule(message: "overtime assignment needs an entry"),
                OvertimeAssignmentAllowedNameRule(allowed: []),
            ]
        )
    }
}
