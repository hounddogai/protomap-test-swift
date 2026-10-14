import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global eligibility forecast must pass. Check returns its problems, or none.
    protocol GlobalEligibilityForecastRule {
        func check(_ item: GlobalEligibilityForecast) -> [String]
    }

    final class GlobalEligibilityForecastRequiredCodeRule: GlobalEligibilityForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalEligibilityForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalEligibilityForecastAllowedLabelRule: GlobalEligibilityForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalEligibilityForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    final class GlobalEligibilityForecastCodeLengthRule: GlobalEligibilityForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalEligibilityForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalEligibilityForecastEncounterIDLengthRule: GlobalEligibilityForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalEligibilityForecast) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global eligibility forecast.
    final class GlobalEligibilityForecastValidator {
        var rules: [any GlobalEligibilityForecastRule]

        init(rules: [any GlobalEligibilityForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalEligibilityForecast) -> [String] {
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

        func requireValid(_ item: GlobalEligibilityForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalEligibilityForecast]) -> [String: [String]] {
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

    static func defaultGlobalEligibilityForecastValidator() -> GlobalEligibilityForecastValidator {
        return GlobalEligibilityForecastValidator(
            rules: [
                GlobalEligibilityForecastRequiredCodeRule(message: "global eligibility forecast needs an entry"),
                GlobalEligibilityForecastAllowedLabelRule(allowed: []),
                GlobalEligibilityForecastCodeLengthRule(maxLength: 120),
                GlobalEligibilityForecastEncounterIDLengthRule(maxLength: 80),
            ]
        )
    }
}
