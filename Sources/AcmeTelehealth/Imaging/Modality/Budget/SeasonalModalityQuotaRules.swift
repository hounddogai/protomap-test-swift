import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal modality quota must pass. Check returns its problems, or none.
    protocol SeasonalModalityQuotaRule {
        func check(_ item: SeasonalModalityQuota) -> [String]
    }

    final class SeasonalModalityQuotaCategoryLengthRule: SeasonalModalityQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalModalityQuota) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalModalityQuotaRequiredLabelRule: SeasonalModalityQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalModalityQuota) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalModalityQuotaLabelLengthRule: SeasonalModalityQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalModalityQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalModalityQuotaCodePrefixRule: SeasonalModalityQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalModalityQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalModalityQuotaRateRangeRule: SeasonalModalityQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalModalityQuota) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a seasonal modality quota.
    final class SeasonalModalityQuotaValidator {
        var rules: [any SeasonalModalityQuotaRule]

        init(rules: [any SeasonalModalityQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalModalityQuota) -> [String] {
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

        func requireValid(_ item: SeasonalModalityQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalModalityQuota]) -> [String: [String]] {
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

    static func defaultSeasonalModalityQuotaValidator() -> SeasonalModalityQuotaValidator {
        return SeasonalModalityQuotaValidator(
            rules: [
                SeasonalModalityQuotaCategoryLengthRule(maxLength: 1000),
                SeasonalModalityQuotaRequiredLabelRule(message: "seasonal modality quota needs an entry"),
                SeasonalModalityQuotaLabelLengthRule(maxLength: 64),
                SeasonalModalityQuotaCodePrefixRule(prefix: "Q"),
                SeasonalModalityQuotaRateRangeRule(min: 3.6, max: 398.5),
            ]
        )
    }
}
