import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient task plan must pass. Check returns its problems, or none.
    protocol LenientTaskPlanRule {
        func check(_ item: LenientTaskPlan) -> [String]
    }

    final class LenientTaskPlanNameLengthRule: LenientTaskPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientTaskPlan) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientTaskPlanAllowedNameRule: LenientTaskPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientTaskPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    final class LenientTaskPlanRequiredCodeRule: LenientTaskPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientTaskPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient task plan.
    final class LenientTaskPlanValidator {
        var rules: [any LenientTaskPlanRule]

        init(rules: [any LenientTaskPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientTaskPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientTaskPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientTaskPlan]) -> [String: [String]] {
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

    static func defaultLenientTaskPlanValidator() -> LenientTaskPlanValidator {
        return LenientTaskPlanValidator(
            rules: [
                LenientTaskPlanNameLengthRule(maxLength: 80),
                LenientTaskPlanAllowedNameRule(allowed: ["regional"]),
                LenientTaskPlanRequiredCodeRule(message: "lenient task plan needs an entry"),
            ]
        )
    }
}
