import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional alert forecast must pass. Check returns its problems, or none.
    protocol RegionalAlertForecastRule {
        func check(_ item: RegionalAlertForecast) -> [String]
    }

    final class RegionalAlertForecastCodePrefixRule: RegionalAlertForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalAlertForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalAlertForecastNameLengthRule: RegionalAlertForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAlertForecast) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalAlertForecastCodeLengthRule: RegionalAlertForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAlertForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional alert forecast.
    final class RegionalAlertForecastValidator {
        var rules: [any RegionalAlertForecastRule]

        init(rules: [any RegionalAlertForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalAlertForecast) -> [String] {
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

        func requireValid(_ item: RegionalAlertForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalAlertForecast]) -> [String: [String]] {
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

    static func defaultRegionalAlertForecastValidator() -> RegionalAlertForecastValidator {
        return RegionalAlertForecastValidator(
            rules: [
                RegionalAlertForecastCodePrefixRule(prefix: "ACM"),
                RegionalAlertForecastNameLengthRule(maxLength: 1000),
                RegionalAlertForecastCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
