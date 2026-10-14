import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default shift forecast must pass. Check returns its problems, or none.
    protocol DefaultShiftForecastRule {
        func check(_ item: DefaultShiftForecast) -> [String]
    }

    final class DefaultShiftForecastBatchSizeRangeRule: DefaultShiftForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultShiftForecast) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultShiftForecastCodePrefixRule: DefaultShiftForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultShiftForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultShiftForecastRequiredNameRule: DefaultShiftForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultShiftForecast) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultShiftForecastAllowedCodeRule: DefaultShiftForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultShiftForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class DefaultShiftForecastSegmentLengthRule: DefaultShiftForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultShiftForecast) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default shift forecast.
    final class DefaultShiftForecastValidator {
        var rules: [any DefaultShiftForecastRule]

        init(rules: [any DefaultShiftForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultShiftForecast) -> [String] {
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

        func requireValid(_ item: DefaultShiftForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultShiftForecast]) -> [String: [String]] {
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

    static func defaultDefaultShiftForecastValidator() -> DefaultShiftForecastValidator {
        return DefaultShiftForecastValidator(
            rules: [
                DefaultShiftForecastBatchSizeRangeRule(min: 1000, max: 86400),
                DefaultShiftForecastCodePrefixRule(prefix: "OPS"),
                DefaultShiftForecastRequiredNameRule(message: "default shift forecast needs this field"),
                DefaultShiftForecastAllowedCodeRule(allowed: ["rolling"]),
                DefaultShiftForecastSegmentLengthRule(maxLength: 16),
            ]
        )
    }
}
