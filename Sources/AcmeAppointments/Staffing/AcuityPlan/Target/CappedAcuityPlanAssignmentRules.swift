import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped acuity plan assignment must pass. Check returns its problems, or none.
    protocol CappedAcuityPlanAssignmentRule {
        func check(_ item: CappedAcuityPlanAssignment) -> [String]
    }

    final class CappedAcuityPlanAssignmentCodeLengthRule: CappedAcuityPlanAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedAcuityPlanAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedAcuityPlanAssignmentRequiredPayerRule: CappedAcuityPlanAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedAcuityPlanAssignment) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedAcuityPlanAssignmentTitleLengthRule: CappedAcuityPlanAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedAcuityPlanAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped acuity plan assignment.
    final class CappedAcuityPlanAssignmentValidator {
        var rules: [any CappedAcuityPlanAssignmentRule]

        init(rules: [any CappedAcuityPlanAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedAcuityPlanAssignment) -> [String] {
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

        func requireValid(_ item: CappedAcuityPlanAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedAcuityPlanAssignment]) -> [String: [String]] {
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

    static func defaultCappedAcuityPlanAssignmentValidator() -> CappedAcuityPlanAssignmentValidator {
        return CappedAcuityPlanAssignmentValidator(
            rules: [
                CappedAcuityPlanAssignmentCodeLengthRule(maxLength: 16),
                CappedAcuityPlanAssignmentRequiredPayerRule(message: "capped acuity plan assignment needs a value"),
                CappedAcuityPlanAssignmentTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
