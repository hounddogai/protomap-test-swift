import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending panel template must pass. Check returns its problems, or none.
    protocol PendingPanelTemplateRule {
        func check(_ item: PendingPanelTemplate) -> [String]
    }

    final class PendingPanelTemplateCodePrefixRule: PendingPanelTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingPanelTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingPanelTemplateRequiredAllergyRule: PendingPanelTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingPanelTemplate) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingPanelTemplateRateRangeRule: PendingPanelTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingPanelTemplate) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingPanelTemplateSummaryLengthRule: PendingPanelTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingPanelTemplate) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending panel template.
    final class PendingPanelTemplateValidator {
        var rules: [any PendingPanelTemplateRule]

        init(rules: [any PendingPanelTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingPanelTemplate) -> [String] {
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

        func requireValid(_ item: PendingPanelTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingPanelTemplate]) -> [String: [String]] {
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

    static func defaultPendingPanelTemplateValidator() -> PendingPanelTemplateValidator {
        return PendingPanelTemplateValidator(
            rules: [
                PendingPanelTemplateCodePrefixRule(prefix: "X"),
                PendingPanelTemplateRequiredAllergyRule(message: "pending panel template needs this field"),
                PendingPanelTemplateRateRangeRule(min: 5.7, max: 2472.4),
                PendingPanelTemplateSummaryLengthRule(maxLength: 16),
            ]
        )
    }
}
