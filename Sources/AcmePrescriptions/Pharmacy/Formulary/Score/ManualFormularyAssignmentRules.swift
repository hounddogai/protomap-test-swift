import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual formulary assignment must pass. Check returns its problems, or none.
    protocol ManualFormularyAssignmentRule {
        func check(_ item: ManualFormularyAssignment) -> [String]
    }

    final class ManualFormularyAssignmentRequiredCodeRule: ManualFormularyAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualFormularyAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualFormularyAssignmentRequiredSummaryRule: ManualFormularyAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualFormularyAssignment) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualFormularyAssignmentAllowedCodeRule: ManualFormularyAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualFormularyAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a manual formulary assignment.
    final class ManualFormularyAssignmentValidator {
        var rules: [any ManualFormularyAssignmentRule]

        init(rules: [any ManualFormularyAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualFormularyAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualFormularyAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualFormularyAssignment]) -> [String: [String]] {
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

    static func defaultManualFormularyAssignmentValidator() -> ManualFormularyAssignmentValidator {
        return ManualFormularyAssignmentValidator(
            rules: [
                ManualFormularyAssignmentRequiredCodeRule(message: "manual formulary assignment needs an entry"),
                ManualFormularyAssignmentRequiredSummaryRule(message: "manual formulary assignment needs this field"),
                ManualFormularyAssignmentAllowedCodeRule(allowed: ["rolling"]),
            ]
        )
    }
}
