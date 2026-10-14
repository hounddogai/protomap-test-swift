import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist template must pass. Check returns its problems, or none.
    protocol WorklistTemplateRule {
        func check(_ item: WorklistTemplate) -> [String]
    }

    final class WorklistTemplateRequiredCodeRule: WorklistTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistTemplateCodePrefixRule: WorklistTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WorklistTemplateEndsAtRangeRule: WorklistTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistTemplate) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a worklist template.
    final class WorklistTemplateValidator {
        var rules: [any WorklistTemplateRule]

        init(rules: [any WorklistTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistTemplate]) -> [String: [String]] {
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

    static func defaultWorklistTemplateValidator() -> WorklistTemplateValidator {
        return WorklistTemplateValidator(
            rules: [
                WorklistTemplateRequiredCodeRule(message: "worklist template needs a value"),
                WorklistTemplateCodePrefixRule(prefix: "OPS"),
                WorklistTemplateEndsAtRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
