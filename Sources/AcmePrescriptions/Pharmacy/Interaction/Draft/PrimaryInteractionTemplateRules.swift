import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary interaction template must pass. Check returns its problems, or none.
    protocol PrimaryInteractionTemplateRule {
        func check(_ item: PrimaryInteractionTemplate) -> [String]
    }

    final class PrimaryInteractionTemplateRequiredLabelRule: PrimaryInteractionTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryInteractionTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryInteractionTemplateMinimumRangeRule: PrimaryInteractionTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryInteractionTemplate) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryInteractionTemplateRateRangeRule: PrimaryInteractionTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryInteractionTemplate) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryInteractionTemplateCodePrefixRule: PrimaryInteractionTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryInteractionTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryInteractionTemplateRequiredTimezoneRule: PrimaryInteractionTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryInteractionTemplate) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary interaction template.
    final class PrimaryInteractionTemplateValidator {
        var rules: [any PrimaryInteractionTemplateRule]

        init(rules: [any PrimaryInteractionTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryInteractionTemplate) -> [String] {
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

        func requireValid(_ item: PrimaryInteractionTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryInteractionTemplate]) -> [String: [String]] {
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

    static func defaultPrimaryInteractionTemplateValidator() -> PrimaryInteractionTemplateValidator {
        return PrimaryInteractionTemplateValidator(
            rules: [
                PrimaryInteractionTemplateRequiredLabelRule(message: "primary interaction template needs a value"),
                PrimaryInteractionTemplateMinimumRangeRule(min: 7.5, max: 3912.7),
                PrimaryInteractionTemplateRateRangeRule(min: 0.1, max: 2705.5),
                PrimaryInteractionTemplateCodePrefixRule(prefix: "Q"),
                PrimaryInteractionTemplateRequiredTimezoneRule(message: "primary interaction template needs an entry"),
            ]
        )
    }
}
