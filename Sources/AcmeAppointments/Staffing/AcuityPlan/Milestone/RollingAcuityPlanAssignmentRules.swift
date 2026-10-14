import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a rolling acuity plan assignment must pass. Check returns its problems, or none.
    protocol RollingAcuityPlanAssignmentRule {
        func check(_ item: RollingAcuityPlanAssignment) -> [String]
    }

    final class RollingAcuityPlanAssignmentRequiredLabelRule: RollingAcuityPlanAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAcuityPlanAssignment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAcuityPlanAssignmentAllowedCodeRule: RollingAcuityPlanAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingAcuityPlanAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class RollingAcuityPlanAssignmentNameLengthRule: RollingAcuityPlanAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAcuityPlanAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAcuityPlanAssignmentRequiredNameRule: RollingAcuityPlanAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAcuityPlanAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling acuity plan assignment.
    final class RollingAcuityPlanAssignmentValidator {
        var rules: [any RollingAcuityPlanAssignmentRule]

        init(rules: [any RollingAcuityPlanAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAcuityPlanAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingAcuityPlanAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAcuityPlanAssignment]) -> [String: [String]] {
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

    static func defaultRollingAcuityPlanAssignmentValidator() -> RollingAcuityPlanAssignmentValidator {
        return RollingAcuityPlanAssignmentValidator(
            rules: [
                RollingAcuityPlanAssignmentRequiredLabelRule(message: "rolling acuity plan assignment needs a value"),
                RollingAcuityPlanAssignmentAllowedCodeRule(allowed: ["manual"]),
                RollingAcuityPlanAssignmentNameLengthRule(maxLength: 64),
                RollingAcuityPlanAssignmentRequiredNameRule(message: "rolling acuity plan assignment needs an entry"),
            ]
        )
    }
}
