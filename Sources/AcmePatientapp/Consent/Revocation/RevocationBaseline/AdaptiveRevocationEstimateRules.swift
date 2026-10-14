import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive revocation estimate must pass. Check returns its problems, or none.
    protocol AdaptiveRevocationEstimateRule {
        func check(_ item: AdaptiveRevocationEstimate) -> [String]
    }

    final class AdaptiveRevocationEstimateRequiredExternalRefRule: AdaptiveRevocationEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRevocationEstimate) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRevocationEstimateCurrencyLengthRule: AdaptiveRevocationEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRevocationEstimate) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRevocationEstimateRequiredCurrencyRule: AdaptiveRevocationEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRevocationEstimate) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRevocationEstimateRequiredCodeRule: AdaptiveRevocationEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRevocationEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRevocationEstimateWindowDaysRangeRule: AdaptiveRevocationEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRevocationEstimate) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveRevocationEstimateRequiredTitleRule: AdaptiveRevocationEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRevocationEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive revocation estimate.
    final class AdaptiveRevocationEstimateValidator {
        var rules: [any AdaptiveRevocationEstimateRule]

        init(rules: [any AdaptiveRevocationEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRevocationEstimate) -> [String] {
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

        func requireValid(_ item: AdaptiveRevocationEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRevocationEstimate]) -> [String: [String]] {
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

    static func defaultAdaptiveRevocationEstimateValidator() -> AdaptiveRevocationEstimateValidator {
        return AdaptiveRevocationEstimateValidator(
            rules: [
                AdaptiveRevocationEstimateRequiredExternalRefRule(
                    message: "adaptive revocation estimate needs an entry"
                ),
                AdaptiveRevocationEstimateCurrencyLengthRule(maxLength: 80),
                AdaptiveRevocationEstimateRequiredCurrencyRule(
                    message: "adaptive revocation estimate needs this field"
                ),
                AdaptiveRevocationEstimateRequiredCodeRule(message: "adaptive revocation estimate needs this field"),
                AdaptiveRevocationEstimateWindowDaysRangeRule(min: 16, max: 120),
                AdaptiveRevocationEstimateRequiredTitleRule(message: "adaptive revocation estimate needs an entry"),
            ]
        )
    }
}
