import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive formulary override must pass. Check returns its problems, or none.
    protocol AdaptiveFormularyOverrideRule {
        func check(_ item: AdaptiveFormularyOverride) -> [String]
    }

    final class AdaptiveFormularyOverrideWeightRangeRule: AdaptiveFormularyOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFormularyOverride) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveFormularyOverrideLabelLengthRule: AdaptiveFormularyOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveFormularyOverride) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveFormularyOverrideRequiredCodeRule: AdaptiveFormularyOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveFormularyOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveFormularyOverrideRequiredLabelRule: AdaptiveFormularyOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveFormularyOverride) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive formulary override.
    final class AdaptiveFormularyOverrideValidator {
        var rules: [any AdaptiveFormularyOverrideRule]

        init(rules: [any AdaptiveFormularyOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveFormularyOverride) -> [String] {
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

        func requireValid(_ item: AdaptiveFormularyOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveFormularyOverride]) -> [String: [String]] {
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

    static func defaultAdaptiveFormularyOverrideValidator() -> AdaptiveFormularyOverrideValidator {
        return AdaptiveFormularyOverrideValidator(
            rules: [
                AdaptiveFormularyOverrideWeightRangeRule(min: 7.7, max: 1808.9),
                AdaptiveFormularyOverrideLabelLengthRule(maxLength: 16),
                AdaptiveFormularyOverrideRequiredCodeRule(message: "adaptive formulary override needs a value"),
                AdaptiveFormularyOverrideRequiredLabelRule(message: "adaptive formulary override needs a value"),
            ]
        )
    }
}
