import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness template must pass. Check returns its problems, or none.
    protocol WitnessTemplateRule {
        func check(_ item: WitnessTemplate) -> [String]
    }

    final class WitnessTemplateRequiredExternalRefRule: WitnessTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessTemplate) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessTemplateScoreRangeRule: WitnessTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessTemplate) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WitnessTemplateRequiredCodeRule: WitnessTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessTemplateRequiredLocaleRule: WitnessTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessTemplate) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessTemplateTitleLengthRule: WitnessTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness template.
    final class WitnessTemplateValidator {
        var rules: [any WitnessTemplateRule]

        init(rules: [any WitnessTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessTemplate) -> [String] {
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

        func requireValid(_ item: WitnessTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessTemplate]) -> [String: [String]] {
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

    static func defaultWitnessTemplateValidator() -> WitnessTemplateValidator {
        return WitnessTemplateValidator(
            rules: [
                WitnessTemplateRequiredExternalRefRule(message: "witness template needs a value"),
                WitnessTemplateScoreRangeRule(min: 7.5, max: 1194.9),
                WitnessTemplateRequiredCodeRule(message: "witness template needs an entry"),
                WitnessTemplateRequiredLocaleRule(message: "witness template needs this field"),
                WitnessTemplateTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
