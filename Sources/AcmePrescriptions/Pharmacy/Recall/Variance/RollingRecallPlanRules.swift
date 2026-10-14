import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling recall plan must pass. Check returns its problems, or none.
    protocol RollingRecallPlanRule {
        func check(_ item: RollingRecallPlan) -> [String]
    }

    final class RollingRecallPlanDosageMgRangeRule: RollingRecallPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingRecallPlan) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingRecallPlanAllowedCodeRule: RollingRecallPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingRecallPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class RollingRecallPlanRequiredCodeRule: RollingRecallPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRecallPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingRecallPlanCodeLengthRule: RollingRecallPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRecallPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingRecallPlanNameLengthRule: RollingRecallPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRecallPlan) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling recall plan.
    final class RollingRecallPlanValidator {
        var rules: [any RollingRecallPlanRule]

        init(rules: [any RollingRecallPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRecallPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingRecallPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRecallPlan]) -> [String: [String]] {
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

    static func defaultRollingRecallPlanValidator() -> RollingRecallPlanValidator {
        return RollingRecallPlanValidator(
            rules: [
                RollingRecallPlanDosageMgRangeRule(min: 9.7, max: 4555.1),
                RollingRecallPlanAllowedCodeRule(allowed: ["manual", "adaptive"]),
                RollingRecallPlanRequiredCodeRule(message: "rolling recall plan needs a value"),
                RollingRecallPlanCodeLengthRule(maxLength: 64),
                RollingRecallPlanNameLengthRule(maxLength: 120),
            ]
        )
    }
}
