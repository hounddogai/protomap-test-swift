import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy reference range forecast must pass. Check returns its problems, or none.
    protocol LegacyReferenceRangeForecastRule {
        func check(_ item: LegacyReferenceRangeForecast) -> [String]
    }

    final class LegacyReferenceRangeForecastLabelLengthRule: LegacyReferenceRangeForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyReferenceRangeForecast) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyReferenceRangeForecastCodeLengthRule: LegacyReferenceRangeForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyReferenceRangeForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyReferenceRangeForecastVisibleGuardRule: LegacyReferenceRangeForecastRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LegacyReferenceRangeForecast) -> [String] {
            if item.visible && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy reference range forecast.
    final class LegacyReferenceRangeForecastValidator {
        var rules: [any LegacyReferenceRangeForecastRule]

        init(rules: [any LegacyReferenceRangeForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyReferenceRangeForecast) -> [String] {
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

        func requireValid(_ item: LegacyReferenceRangeForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyReferenceRangeForecast]) -> [String: [String]] {
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

    static func defaultLegacyReferenceRangeForecastValidator() -> LegacyReferenceRangeForecastValidator {
        return LegacyReferenceRangeForecastValidator(
            rules: [
                LegacyReferenceRangeForecastLabelLengthRule(maxLength: 64),
                LegacyReferenceRangeForecastCodeLengthRule(maxLength: 120),
                LegacyReferenceRangeForecastVisibleGuardRule(limit: 32),
            ]
        )
    }
}
