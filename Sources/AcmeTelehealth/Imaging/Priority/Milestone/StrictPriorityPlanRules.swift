import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict priority plan must pass. Check returns its problems, or none.
    protocol StrictPriorityPlanRule {
        func check(_ item: StrictPriorityPlan) -> [String]
    }

    final class StrictPriorityPlanCodeLengthRule: StrictPriorityPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictPriorityPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictPriorityPlanRequiredCodeRule: StrictPriorityPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictPriorityPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictPriorityPlanDiagnosisCodeLengthRule: StrictPriorityPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictPriorityPlan) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictPriorityPlanRequiredTitleRule: StrictPriorityPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictPriorityPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictPriorityPlanCopayRangeRule: StrictPriorityPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictPriorityPlan) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictPriorityPlanAllowedDiagnosisCodeRule: StrictPriorityPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictPriorityPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a strict priority plan.
    final class StrictPriorityPlanValidator {
        var rules: [any StrictPriorityPlanRule]

        init(rules: [any StrictPriorityPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictPriorityPlan) -> [String] {
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

        func requireValid(_ item: StrictPriorityPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictPriorityPlan]) -> [String: [String]] {
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

    static func defaultStrictPriorityPlanValidator() -> StrictPriorityPlanValidator {
        return StrictPriorityPlanValidator(
            rules: [
                StrictPriorityPlanCodeLengthRule(maxLength: 120),
                StrictPriorityPlanRequiredCodeRule(message: "strict priority plan needs a value"),
                StrictPriorityPlanDiagnosisCodeLengthRule(maxLength: 86400),
                StrictPriorityPlanRequiredTitleRule(message: "strict priority plan needs this field"),
                StrictPriorityPlanCopayRangeRule(min: 3.6, max: 3225.1),
                StrictPriorityPlanAllowedDiagnosisCodeRule(allowed: []),
            ]
        )
    }
}
