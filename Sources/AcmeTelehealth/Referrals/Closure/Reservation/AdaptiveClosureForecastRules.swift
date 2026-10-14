import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive closure forecast must pass. Check returns its problems, or none.
    protocol AdaptiveClosureForecastRule {
        func check(_ item: AdaptiveClosureForecast) -> [String]
    }

    final class AdaptiveClosureForecastDescriptionLengthRule: AdaptiveClosureForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveClosureForecast) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveClosureForecastPayerLengthRule: AdaptiveClosureForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveClosureForecast) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveClosureForecastAllowedCodeRule: AdaptiveClosureForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveClosureForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class AdaptiveClosureForecastVisitMinutesRangeRule: AdaptiveClosureForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveClosureForecast) -> [String] {
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

    final class AdaptiveClosureForecastCapacityRangeRule: AdaptiveClosureForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveClosureForecast) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveClosureForecastQuantityRangeRule: AdaptiveClosureForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveClosureForecast) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive closure forecast.
    final class AdaptiveClosureForecastValidator {
        var rules: [any AdaptiveClosureForecastRule]

        init(rules: [any AdaptiveClosureForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveClosureForecast) -> [String] {
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

        func requireValid(_ item: AdaptiveClosureForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveClosureForecast]) -> [String: [String]] {
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

    static func defaultAdaptiveClosureForecastValidator() -> AdaptiveClosureForecastValidator {
        return AdaptiveClosureForecastValidator(
            rules: [
                AdaptiveClosureForecastDescriptionLengthRule(maxLength: 64),
                AdaptiveClosureForecastPayerLengthRule(maxLength: 64),
                AdaptiveClosureForecastAllowedCodeRule(allowed: ["manual", "seasonal"]),
                AdaptiveClosureForecastVisitMinutesRangeRule(min: 32, max: 64),
                AdaptiveClosureForecastCapacityRangeRule(min: 255, max: 3600),
                AdaptiveClosureForecastQuantityRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
