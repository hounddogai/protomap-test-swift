import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched follow up template must pass. Check returns its problems, or none.
    protocol BatchedFollowUpTemplateRule {
        func check(_ item: BatchedFollowUpTemplate) -> [String]
    }

    final class BatchedFollowUpTemplateCodePrefixRule: BatchedFollowUpTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedFollowUpTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedFollowUpTemplateDosageMgRangeRule: BatchedFollowUpTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedFollowUpTemplate) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedFollowUpTemplateRequiredCodeRule: BatchedFollowUpTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedFollowUpTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched follow up template.
    final class BatchedFollowUpTemplateValidator {
        var rules: [any BatchedFollowUpTemplateRule]

        init(rules: [any BatchedFollowUpTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedFollowUpTemplate) -> [String] {
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

        func requireValid(_ item: BatchedFollowUpTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedFollowUpTemplate]) -> [String: [String]] {
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

    static func defaultBatchedFollowUpTemplateValidator() -> BatchedFollowUpTemplateValidator {
        return BatchedFollowUpTemplateValidator(
            rules: [
                BatchedFollowUpTemplateCodePrefixRule(prefix: "OPS"),
                BatchedFollowUpTemplateDosageMgRangeRule(min: 8.6, max: 334.2),
                BatchedFollowUpTemplateRequiredCodeRule(message: "batched follow up template needs an entry"),
            ]
        )
    }
}
