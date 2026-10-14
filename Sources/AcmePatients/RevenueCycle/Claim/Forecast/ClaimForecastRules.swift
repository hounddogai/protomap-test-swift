import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim forecast must pass. Check returns its problems, or none.
    protocol ClaimForecastRule {
        func check(_ item: ClaimForecast) -> [String]
    }

    final class ClaimForecastRequiredLabelRule: ClaimForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimForecast) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimForecastEncounterIDLengthRule: ClaimForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimForecast) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimForecastCodeLengthRule: ClaimForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimForecastRequiredCodeRule: ClaimForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimForecastLabelLengthRule: ClaimForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimForecast) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim forecast.
    final class ClaimForecastValidator {
        var rules: [any ClaimForecastRule]

        init(rules: [any ClaimForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimForecast) -> [String] {
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

        func requireValid(_ item: ClaimForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimForecast]) -> [String: [String]] {
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

    static func defaultClaimForecastValidator() -> ClaimForecastValidator {
        return ClaimForecastValidator(
            rules: [
                ClaimForecastRequiredLabelRule(message: "claim forecast needs this field"),
                ClaimForecastEncounterIDLengthRule(maxLength: 255),
                ClaimForecastCodeLengthRule(maxLength: 1000),
                ClaimForecastRequiredCodeRule(message: "claim forecast needs a value"),
                ClaimForecastLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
