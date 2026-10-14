import AcmePlatform
import Foundation

extension Labs {
    /// A rule a manual reference range forecast must pass. Check returns its problems, or none.
    protocol ManualReferenceRangeForecastRule {
        func check(_ item: ManualReferenceRangeForecast) -> [String]
    }

    final class ManualReferenceRangeForecastRequiredCodeRule: ManualReferenceRangeForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualReferenceRangeForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualReferenceRangeForecastCodePrefixRule: ManualReferenceRangeForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualReferenceRangeForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualReferenceRangeForecastRequiredAllergyRule: ManualReferenceRangeForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualReferenceRangeForecast) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualReferenceRangeForecastAllowedAllergyRule: ManualReferenceRangeForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualReferenceRangeForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a manual reference range forecast.
    final class ManualReferenceRangeForecastValidator {
        var rules: [any ManualReferenceRangeForecastRule]

        init(rules: [any ManualReferenceRangeForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualReferenceRangeForecast) -> [String] {
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

        func requireValid(_ item: ManualReferenceRangeForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualReferenceRangeForecast]) -> [String: [String]] {
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

    static func defaultManualReferenceRangeForecastValidator() -> ManualReferenceRangeForecastValidator {
        return ManualReferenceRangeForecastValidator(
            rules: [
                ManualReferenceRangeForecastRequiredCodeRule(
                    message: "manual reference range forecast needs this field"
                ),
                ManualReferenceRangeForecastCodePrefixRule(prefix: "Q"),
                ManualReferenceRangeForecastRequiredAllergyRule(
                    message: "manual reference range forecast needs a value"
                ),
                ManualReferenceRangeForecastAllowedAllergyRule(allowed: ["rolling", "seasonal", "strict"]),
            ]
        )
    }
}
