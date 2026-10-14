import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy isolation forecast must pass. Check returns its problems, or none.
    protocol LegacyIsolationForecastRule {
        func check(_ item: LegacyIsolationForecast) -> [String]
    }

    final class LegacyIsolationForecastEncounterIDLengthRule: LegacyIsolationForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyIsolationForecast) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyIsolationForecastUpdatedAtRangeRule: LegacyIsolationForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyIsolationForecast) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyIsolationForecastRequiredCodeRule: LegacyIsolationForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyIsolationForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyIsolationForecastChecksumLengthRule: LegacyIsolationForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyIsolationForecast) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyIsolationForecastCodeLengthRule: LegacyIsolationForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyIsolationForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyIsolationForecastNameLengthRule: LegacyIsolationForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyIsolationForecast) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy isolation forecast.
    final class LegacyIsolationForecastValidator {
        var rules: [any LegacyIsolationForecastRule]

        init(rules: [any LegacyIsolationForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyIsolationForecast) -> [String] {
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

        func requireValid(_ item: LegacyIsolationForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyIsolationForecast]) -> [String: [String]] {
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

    static func defaultLegacyIsolationForecastValidator() -> LegacyIsolationForecastValidator {
        return LegacyIsolationForecastValidator(
            rules: [
                LegacyIsolationForecastEncounterIDLengthRule(maxLength: 255),
                LegacyIsolationForecastUpdatedAtRangeRule(min: 32, max: 1000),
                LegacyIsolationForecastRequiredCodeRule(message: "legacy isolation forecast needs an entry"),
                LegacyIsolationForecastChecksumLengthRule(maxLength: 86400),
                LegacyIsolationForecastCodeLengthRule(maxLength: 120),
                LegacyIsolationForecastNameLengthRule(maxLength: 64),
            ]
        )
    }
}
