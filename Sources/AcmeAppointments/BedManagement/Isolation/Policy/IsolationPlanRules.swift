import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation plan must pass. Check returns its problems, or none.
    protocol IsolationPlanRule {
        func check(_ item: IsolationPlan) -> [String]
    }

    final class IsolationPlanRequiredSummaryRule: IsolationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationPlan) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationPlanCodeLengthRule: IsolationPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationPlanRequiredEncounterIDRule: IsolationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationPlan) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a isolation plan.
    final class IsolationPlanValidator {
        var rules: [any IsolationPlanRule]

        init(rules: [any IsolationPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationPlan) -> [String] {
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

        func requireValid(_ item: IsolationPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationPlan]) -> [String: [String]] {
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

    static func defaultIsolationPlanValidator() -> IsolationPlanValidator {
        return IsolationPlanValidator(
            rules: [
                IsolationPlanRequiredSummaryRule(message: "isolation plan needs a value"),
                IsolationPlanCodeLengthRule(maxLength: 3600),
                IsolationPlanRequiredEncounterIDRule(message: "isolation plan needs a value"),
            ]
        )
    }
}
