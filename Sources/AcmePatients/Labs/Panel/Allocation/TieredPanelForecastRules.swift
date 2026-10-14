import AcmePlatform
import Foundation

extension Labs {
    /// A rule a tiered panel forecast must pass. Check returns its problems, or none.
    protocol TieredPanelForecastRule {
        func check(_ item: TieredPanelForecast) -> [String]
    }

    final class TieredPanelForecastGraceDaysRangeRule: TieredPanelForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredPanelForecast) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredPanelForecastAllowedTitleRule: TieredPanelForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredPanelForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class TieredPanelForecastTitleLengthRule: TieredPanelForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPanelForecast) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredPanelForecastVisitMinutesRangeRule: TieredPanelForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredPanelForecast) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered panel forecast.
    final class TieredPanelForecastValidator {
        var rules: [any TieredPanelForecastRule]

        init(rules: [any TieredPanelForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredPanelForecast) -> [String] {
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

        func requireValid(_ item: TieredPanelForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredPanelForecast]) -> [String: [String]] {
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

    static func defaultTieredPanelForecastValidator() -> TieredPanelForecastValidator {
        return TieredPanelForecastValidator(
            rules: [
                TieredPanelForecastGraceDaysRangeRule(min: 3600, max: 3600),
                TieredPanelForecastAllowedTitleRule(allowed: []),
                TieredPanelForecastTitleLengthRule(maxLength: 32),
                TieredPanelForecastVisitMinutesRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
