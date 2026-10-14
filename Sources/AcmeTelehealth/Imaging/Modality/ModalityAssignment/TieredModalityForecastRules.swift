import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered modality forecast must pass. Check returns its problems, or none.
    protocol TieredModalityForecastRule {
        func check(_ item: TieredModalityForecast) -> [String]
    }

    final class TieredModalityForecastRequiredCodeRule: TieredModalityForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredModalityForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredModalityForecastVisibleGuardRule: TieredModalityForecastRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TieredModalityForecast) -> [String] {
            if item.visible && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class TieredModalityForecastRequiredBedRule: TieredModalityForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredModalityForecast) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredModalityForecastMarginRangeRule: TieredModalityForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredModalityForecast) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredModalityForecastAllowedBedRule: TieredModalityForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredModalityForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered modality forecast.
    final class TieredModalityForecastValidator {
        var rules: [any TieredModalityForecastRule]

        init(rules: [any TieredModalityForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredModalityForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredModalityForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredModalityForecast]) -> [String: [String]] {
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

    static func defaultTieredModalityForecastValidator() -> TieredModalityForecastValidator {
        return TieredModalityForecastValidator(
            rules: [
                TieredModalityForecastRequiredCodeRule(message: "tiered modality forecast needs a value"),
                TieredModalityForecastVisibleGuardRule(limit: 9.7),
                TieredModalityForecastRequiredBedRule(message: "tiered modality forecast needs this field"),
                TieredModalityForecastMarginRangeRule(min: 6.3, max: 1679.4),
                TieredModalityForecastAllowedBedRule(allowed: ["adaptive", "global"]),
            ]
        )
    }
}
