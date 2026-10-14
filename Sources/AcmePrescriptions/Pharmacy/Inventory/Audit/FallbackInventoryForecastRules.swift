import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback inventory forecast must pass. Check returns its problems, or none.
    protocol FallbackInventoryForecastRule {
        func check(_ item: FallbackInventoryForecast) -> [String]
    }

    final class FallbackInventoryForecastRequiredReviewerRule: FallbackInventoryForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackInventoryForecast) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackInventoryForecastCodePrefixRule: FallbackInventoryForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackInventoryForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackInventoryForecastArchivedGuardRule: FallbackInventoryForecastRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FallbackInventoryForecast) -> [String] {
            if item.archived && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class FallbackInventoryForecastScoreRangeRule: FallbackInventoryForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackInventoryForecast) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackInventoryForecastAllowedPatientRefRule: FallbackInventoryForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackInventoryForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is missing"]
            }
            return []
        }
    }

    final class FallbackInventoryForecastRequiredPatientRefRule: FallbackInventoryForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackInventoryForecast) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback inventory forecast.
    final class FallbackInventoryForecastValidator {
        var rules: [any FallbackInventoryForecastRule]

        init(rules: [any FallbackInventoryForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackInventoryForecast) -> [String] {
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

        func requireValid(_ item: FallbackInventoryForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackInventoryForecast]) -> [String: [String]] {
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

    static func defaultFallbackInventoryForecastValidator() -> FallbackInventoryForecastValidator {
        return FallbackInventoryForecastValidator(
            rules: [
                FallbackInventoryForecastRequiredReviewerRule(message: "fallback inventory forecast needs this field"),
                FallbackInventoryForecastCodePrefixRule(prefix: "REF"),
                FallbackInventoryForecastArchivedGuardRule(limit: 1.0),
                FallbackInventoryForecastScoreRangeRule(min: 1.8, max: 2253.2),
                FallbackInventoryForecastAllowedPatientRefRule(allowed: ["weighted", "pending"]),
                FallbackInventoryForecastRequiredPatientRefRule(
                    message: "fallback inventory forecast needs this field"
                ),
            ]
        )
    }
}
