import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility forecast must pass. Check returns its problems, or none.
    protocol EligibilityForecastRule {
        func check(_ item: EligibilityForecast) -> [String]
    }

    final class EligibilityForecastLabelLengthRule: EligibilityForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityForecast) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityForecastRequiredLabelRule: EligibilityForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityForecast) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityForecastWardLengthRule: EligibilityForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityForecast) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityForecastAcuityRangeRule: EligibilityForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityForecast) -> [String] {
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

    final class EligibilityForecastVisibleGuardRule: EligibilityForecastRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: EligibilityForecast) -> [String] {
            if item.visible && (item.weight > limit) {
                return ["weight \(item.weight) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class EligibilityForecastAllowedWardRule: EligibilityForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility forecast.
    final class EligibilityForecastValidator {
        var rules: [any EligibilityForecastRule]

        init(rules: [any EligibilityForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityForecast]) -> [String: [String]] {
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

    static func defaultEligibilityForecastValidator() -> EligibilityForecastValidator {
        return EligibilityForecastValidator(
            rules: [
                EligibilityForecastLabelLengthRule(maxLength: 32),
                EligibilityForecastRequiredLabelRule(message: "eligibility forecast needs an entry"),
                EligibilityForecastWardLengthRule(maxLength: 86400),
                EligibilityForecastAcuityRangeRule(min: 80, max: 120),
                EligibilityForecastVisibleGuardRule(limit: 6.5),
                EligibilityForecastAllowedWardRule(allowed: ["primary", "adaptive"]),
            ]
        )
    }
}
