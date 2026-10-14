import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive modality forecast must pass. Check returns its problems, or none.
    protocol AdaptiveModalityForecastRule {
        func check(_ item: AdaptiveModalityForecast) -> [String]
    }

    final class AdaptiveModalityForecastApprovedGuardRule: AdaptiveModalityForecastRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AdaptiveModalityForecast) -> [String] {
            if item.approved && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class AdaptiveModalityForecastCategoryLengthRule: AdaptiveModalityForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveModalityForecast) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveModalityForecastRequiredCategoryRule: AdaptiveModalityForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveModalityForecast) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveModalityForecastRequiredLabelRule: AdaptiveModalityForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveModalityForecast) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveModalityForecastAllowedLabelRule: AdaptiveModalityForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveModalityForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive modality forecast.
    final class AdaptiveModalityForecastValidator {
        var rules: [any AdaptiveModalityForecastRule]

        init(rules: [any AdaptiveModalityForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveModalityForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveModalityForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveModalityForecast]) -> [String: [String]] {
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

    static func defaultAdaptiveModalityForecastValidator() -> AdaptiveModalityForecastValidator {
        return AdaptiveModalityForecastValidator(
            rules: [
                AdaptiveModalityForecastApprovedGuardRule(limit: 86400),
                AdaptiveModalityForecastCategoryLengthRule(maxLength: 64),
                AdaptiveModalityForecastRequiredCategoryRule(message: "adaptive modality forecast needs a value"),
                AdaptiveModalityForecastRequiredLabelRule(message: "adaptive modality forecast needs a value"),
                AdaptiveModalityForecastAllowedLabelRule(allowed: ["pending"]),
            ]
        )
    }
}
