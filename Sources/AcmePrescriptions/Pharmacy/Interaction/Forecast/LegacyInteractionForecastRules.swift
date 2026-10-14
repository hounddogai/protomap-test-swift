import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy interaction forecast must pass. Check returns its problems, or none.
    protocol LegacyInteractionForecastRule {
        func check(_ item: LegacyInteractionForecast) -> [String]
    }

    final class LegacyInteractionForecastTitleLengthRule: LegacyInteractionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyInteractionForecast) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyInteractionForecastRequiredTitleRule: LegacyInteractionForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyInteractionForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyInteractionForecastCodePrefixRule: LegacyInteractionForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyInteractionForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyInteractionForecastWardLengthRule: LegacyInteractionForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyInteractionForecast) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy interaction forecast.
    final class LegacyInteractionForecastValidator {
        var rules: [any LegacyInteractionForecastRule]

        init(rules: [any LegacyInteractionForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyInteractionForecast) -> [String] {
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

        func requireValid(_ item: LegacyInteractionForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyInteractionForecast]) -> [String: [String]] {
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

    static func defaultLegacyInteractionForecastValidator() -> LegacyInteractionForecastValidator {
        return LegacyInteractionForecastValidator(
            rules: [
                LegacyInteractionForecastTitleLengthRule(maxLength: 80),
                LegacyInteractionForecastRequiredTitleRule(message: "legacy interaction forecast needs this field"),
                LegacyInteractionForecastCodePrefixRule(prefix: "X"),
                LegacyInteractionForecastWardLengthRule(maxLength: 3600),
            ]
        )
    }
}
