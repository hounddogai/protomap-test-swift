import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen forecast must pass. Check returns its problems, or none.
    protocol SpecimenForecastRule {
        func check(_ item: SpecimenForecast) -> [String]
    }

    final class SpecimenForecastSegmentLengthRule: SpecimenForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenForecast) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenForecastCodePrefixRule: SpecimenForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SpecimenForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SpecimenForecastRequiredCodeRule: SpecimenForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenForecastDosageMgRangeRule: SpecimenForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenForecast) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a specimen forecast.
    final class SpecimenForecastValidator {
        var rules: [any SpecimenForecastRule]

        init(rules: [any SpecimenForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenForecast) -> [String] {
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

        func requireValid(_ item: SpecimenForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenForecast]) -> [String: [String]] {
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

    static func defaultSpecimenForecastValidator() -> SpecimenForecastValidator {
        return SpecimenForecastValidator(
            rules: [
                SpecimenForecastSegmentLengthRule(maxLength: 32),
                SpecimenForecastCodePrefixRule(prefix: "REF"),
                SpecimenForecastRequiredCodeRule(message: "specimen forecast needs a value"),
                SpecimenForecastDosageMgRangeRule(min: 4.0, max: 1621.7),
            ]
        )
    }
}
