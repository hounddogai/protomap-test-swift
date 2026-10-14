import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback float pool schedule must pass. Check returns its problems, or none.
    protocol FallbackFloatPoolScheduleRule {
        func check(_ item: FallbackFloatPoolSchedule) -> [String]
    }

    final class FallbackFloatPoolScheduleAllowedCodeRule: FallbackFloatPoolScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackFloatPoolSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class FallbackFloatPoolScheduleThresholdRangeRule: FallbackFloatPoolScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackFloatPoolSchedule) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackFloatPoolScheduleRequiredCountryRule: FallbackFloatPoolScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackFloatPoolSchedule) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback float pool schedule.
    final class FallbackFloatPoolScheduleValidator {
        var rules: [any FallbackFloatPoolScheduleRule]

        init(rules: [any FallbackFloatPoolScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackFloatPoolSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackFloatPoolSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackFloatPoolSchedule]) -> [String: [String]] {
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

    static func defaultFallbackFloatPoolScheduleValidator() -> FallbackFloatPoolScheduleValidator {
        return FallbackFloatPoolScheduleValidator(
            rules: [
                FallbackFloatPoolScheduleAllowedCodeRule(allowed: []),
                FallbackFloatPoolScheduleThresholdRangeRule(min: 1.5, max: 3674.6),
                FallbackFloatPoolScheduleRequiredCountryRule(message: "fallback float pool schedule needs a value"),
            ]
        )
    }
}
