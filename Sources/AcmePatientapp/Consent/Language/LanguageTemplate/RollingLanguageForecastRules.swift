import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling language forecast must pass. Check returns its problems, or none.
    protocol RollingLanguageForecastRule {
        func check(_ item: RollingLanguageForecast) -> [String]
    }

    final class RollingLanguageForecastCodeLengthRule: RollingLanguageForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingLanguageForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingLanguageForecastPatientRefLengthRule: RollingLanguageForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingLanguageForecast) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingLanguageForecastRequiredSegmentRule: RollingLanguageForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingLanguageForecast) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingLanguageForecastCodePrefixRule: RollingLanguageForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingLanguageForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingLanguageForecastLabelLengthRule: RollingLanguageForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingLanguageForecast) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling language forecast.
    final class RollingLanguageForecastValidator {
        var rules: [any RollingLanguageForecastRule]

        init(rules: [any RollingLanguageForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingLanguageForecast) -> [String] {
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

        func requireValid(_ item: RollingLanguageForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingLanguageForecast]) -> [String: [String]] {
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

    static func defaultRollingLanguageForecastValidator() -> RollingLanguageForecastValidator {
        return RollingLanguageForecastValidator(
            rules: [
                RollingLanguageForecastCodeLengthRule(maxLength: 80),
                RollingLanguageForecastPatientRefLengthRule(maxLength: 1000),
                RollingLanguageForecastRequiredSegmentRule(message: "rolling language forecast needs an entry"),
                RollingLanguageForecastCodePrefixRule(prefix: "X"),
                RollingLanguageForecastLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
