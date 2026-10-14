import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime forecast must pass. Check returns its problems, or none.
    protocol OvertimeForecastRule {
        func check(_ item: OvertimeForecast) -> [String]
    }

    final class OvertimeForecastLabelLengthRule: OvertimeForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeForecast) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeForecastRequiredLabelRule: OvertimeForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeForecast) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeForecastVisibleGuardRule: OvertimeForecastRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: OvertimeForecast) -> [String] {
            if item.visible && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class OvertimeForecastRefillsRangeRule: OvertimeForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeForecast) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OvertimeForecastCodePrefixRule: OvertimeForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OvertimeForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OvertimeForecastWardLengthRule: OvertimeForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeForecast) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime forecast.
    final class OvertimeForecastValidator {
        var rules: [any OvertimeForecastRule]

        init(rules: [any OvertimeForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeForecast) -> [String] {
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

        func requireValid(_ item: OvertimeForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeForecast]) -> [String: [String]] {
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

    static func defaultOvertimeForecastValidator() -> OvertimeForecastValidator {
        return OvertimeForecastValidator(
            rules: [
                OvertimeForecastLabelLengthRule(maxLength: 32),
                OvertimeForecastRequiredLabelRule(message: "overtime forecast needs a value"),
                OvertimeForecastVisibleGuardRule(limit: 32),
                OvertimeForecastRefillsRangeRule(min: 64, max: 1000),
                OvertimeForecastCodePrefixRule(prefix: "OPS"),
                OvertimeForecastWardLengthRule(maxLength: 3600),
            ]
        )
    }
}
