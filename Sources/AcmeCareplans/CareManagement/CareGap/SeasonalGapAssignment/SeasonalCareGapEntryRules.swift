import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal care gap entry must pass. Check returns its problems, or none.
    protocol SeasonalCareGapEntryRule {
        func check(_ item: SeasonalCareGapEntry) -> [String]
    }

    final class SeasonalCareGapEntryRequiredAllergyRule: SeasonalCareGapEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCareGapEntry) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCareGapEntryVersionRangeRule: SeasonalCareGapEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareGapEntry) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalCareGapEntryCodePrefixRule: SeasonalCareGapEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalCareGapEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalCareGapEntryAllowedCurrencyRule: SeasonalCareGapEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalCareGapEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal care gap entry.
    final class SeasonalCareGapEntryValidator {
        var rules: [any SeasonalCareGapEntryRule]

        init(rules: [any SeasonalCareGapEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCareGapEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalCareGapEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCareGapEntry]) -> [String: [String]] {
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

    static func defaultSeasonalCareGapEntryValidator() -> SeasonalCareGapEntryValidator {
        return SeasonalCareGapEntryValidator(
            rules: [
                SeasonalCareGapEntryRequiredAllergyRule(message: "seasonal care gap entry needs this field"),
                SeasonalCareGapEntryVersionRangeRule(min: 120, max: 1000),
                SeasonalCareGapEntryCodePrefixRule(prefix: "X"),
                SeasonalCareGapEntryAllowedCurrencyRule(allowed: []),
            ]
        )
    }
}
