import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual read plan must pass. Check returns its problems, or none.
    protocol ManualReadPlanRule {
        func check(_ item: ManualReadPlan) -> [String]
    }

    final class ManualReadPlanWindowDaysRangeRule: ManualReadPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualReadPlan) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualReadPlanRequiredOwnerIDRule: ManualReadPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualReadPlan) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualReadPlanLimitRangeRule: ManualReadPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualReadPlan) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual read plan.
    final class ManualReadPlanValidator {
        var rules: [any ManualReadPlanRule]

        init(rules: [any ManualReadPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualReadPlan) -> [String] {
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

        func requireValid(_ item: ManualReadPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualReadPlan]) -> [String: [String]] {
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

    static func defaultManualReadPlanValidator() -> ManualReadPlanValidator {
        return ManualReadPlanValidator(
            rules: [
                ManualReadPlanWindowDaysRangeRule(min: 255, max: 1000),
                ManualReadPlanRequiredOwnerIDRule(message: "manual read plan needs this field"),
                ManualReadPlanLimitRangeRule(min: 1000, max: 86400),
            ]
        )
    }
}
