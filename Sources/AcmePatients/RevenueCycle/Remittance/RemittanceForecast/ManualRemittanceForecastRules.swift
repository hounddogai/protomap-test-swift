import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual remittance forecast must pass. Check returns its problems, or none.
    protocol ManualRemittanceForecastRule {
        func check(_ item: ManualRemittanceForecast) -> [String]
    }

    final class ManualRemittanceForecastRequiredCategoryRule: ManualRemittanceForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRemittanceForecast) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRemittanceForecastAcuityRangeRule: ManualRemittanceForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRemittanceForecast) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualRemittanceForecastAllowedTitleRule: ManualRemittanceForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualRemittanceForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a manual remittance forecast.
    final class ManualRemittanceForecastValidator {
        var rules: [any ManualRemittanceForecastRule]

        init(rules: [any ManualRemittanceForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRemittanceForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualRemittanceForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRemittanceForecast]) -> [String: [String]] {
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

    static func defaultManualRemittanceForecastValidator() -> ManualRemittanceForecastValidator {
        return ManualRemittanceForecastValidator(
            rules: [
                ManualRemittanceForecastRequiredCategoryRule(message: "manual remittance forecast needs an entry"),
                ManualRemittanceForecastAcuityRangeRule(min: 64, max: 3600),
                ManualRemittanceForecastAllowedTitleRule(allowed: ["lenient", "weighted"]),
            ]
        )
    }
}
