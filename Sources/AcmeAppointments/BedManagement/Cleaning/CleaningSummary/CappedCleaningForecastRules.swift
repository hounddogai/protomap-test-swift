import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped cleaning forecast must pass. Check returns its problems, or none.
    protocol CappedCleaningForecastRule {
        func check(_ item: CappedCleaningForecast) -> [String]
    }

    final class CappedCleaningForecastRequiredSourceRule: CappedCleaningForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCleaningForecast) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCleaningForecastSummaryLengthRule: CappedCleaningForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCleaningForecast) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCleaningForecastMarginRangeRule: CappedCleaningForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCleaningForecast) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedCleaningForecastAcuityRangeRule: CappedCleaningForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCleaningForecast) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedCleaningForecastAllowedTitleRule: CappedCleaningForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedCleaningForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    final class CappedCleaningForecastCopayRangeRule: CappedCleaningForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCleaningForecast) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped cleaning forecast.
    final class CappedCleaningForecastValidator {
        var rules: [any CappedCleaningForecastRule]

        init(rules: [any CappedCleaningForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCleaningForecast) -> [String] {
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

        func requireValid(_ item: CappedCleaningForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCleaningForecast]) -> [String: [String]] {
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

    static func defaultCappedCleaningForecastValidator() -> CappedCleaningForecastValidator {
        return CappedCleaningForecastValidator(
            rules: [
                CappedCleaningForecastRequiredSourceRule(message: "capped cleaning forecast needs this field"),
                CappedCleaningForecastSummaryLengthRule(maxLength: 32),
                CappedCleaningForecastMarginRangeRule(min: 3.2, max: 3354.4),
                CappedCleaningForecastAcuityRangeRule(min: 32, max: 80),
                CappedCleaningForecastAllowedTitleRule(allowed: ["global", "weighted", "regional"]),
                CappedCleaningForecastCopayRangeRule(min: 8.3, max: 102.7),
            ]
        )
    }
}
