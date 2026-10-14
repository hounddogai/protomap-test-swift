import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal credential variance must pass. Check returns its problems, or none.
    protocol SeasonalCredentialVarianceRule {
        func check(_ item: SeasonalCredentialVariance) -> [String]
    }

    final class SeasonalCredentialVarianceBatchSizeRangeRule: SeasonalCredentialVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCredentialVariance) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalCredentialVarianceCodePrefixRule: SeasonalCredentialVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalCredentialVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalCredentialVarianceRequiredLabelRule: SeasonalCredentialVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCredentialVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCredentialVarianceLimitRangeRule: SeasonalCredentialVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCredentialVariance) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalCredentialVarianceLabelLengthRule: SeasonalCredentialVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCredentialVariance) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCredentialVarianceDiscountRangeRule: SeasonalCredentialVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCredentialVariance) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal credential variance.
    final class SeasonalCredentialVarianceValidator {
        var rules: [any SeasonalCredentialVarianceRule]

        init(rules: [any SeasonalCredentialVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCredentialVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalCredentialVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCredentialVariance]) -> [String: [String]] {
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

    static func defaultSeasonalCredentialVarianceValidator() -> SeasonalCredentialVarianceValidator {
        return SeasonalCredentialVarianceValidator(
            rules: [
                SeasonalCredentialVarianceBatchSizeRangeRule(min: 120, max: 3600),
                SeasonalCredentialVarianceCodePrefixRule(prefix: "Q"),
                SeasonalCredentialVarianceRequiredLabelRule(message: "seasonal credential variance needs a value"),
                SeasonalCredentialVarianceLimitRangeRule(min: 80, max: 3600),
                SeasonalCredentialVarianceLabelLengthRule(maxLength: 64),
                SeasonalCredentialVarianceDiscountRangeRule(min: 6.6, max: 4186.7),
            ]
        )
    }
}
