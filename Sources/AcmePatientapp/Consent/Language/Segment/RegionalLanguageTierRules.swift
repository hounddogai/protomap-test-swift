import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional language tier must pass. Check returns its problems, or none.
    protocol RegionalLanguageTierRule {
        func check(_ item: RegionalLanguageTier) -> [String]
    }

    final class RegionalLanguageTierRequiredDescriptionRule: RegionalLanguageTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalLanguageTier) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalLanguageTierBatchSizeRangeRule: RegionalLanguageTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalLanguageTier) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalLanguageTierRequiredCategoryRule: RegionalLanguageTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalLanguageTier) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalLanguageTierCodePrefixRule: RegionalLanguageTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalLanguageTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalLanguageTierCategoryLengthRule: RegionalLanguageTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalLanguageTier) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional language tier.
    final class RegionalLanguageTierValidator {
        var rules: [any RegionalLanguageTierRule]

        init(rules: [any RegionalLanguageTierRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalLanguageTier) -> [String] {
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

        func requireValid(_ item: RegionalLanguageTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalLanguageTier]) -> [String: [String]] {
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

    static func defaultRegionalLanguageTierValidator() -> RegionalLanguageTierValidator {
        return RegionalLanguageTierValidator(
            rules: [
                RegionalLanguageTierRequiredDescriptionRule(message: "regional language tier needs a value"),
                RegionalLanguageTierBatchSizeRangeRule(min: 1000, max: 3600),
                RegionalLanguageTierRequiredCategoryRule(message: "regional language tier needs an entry"),
                RegionalLanguageTierCodePrefixRule(prefix: "Q"),
                RegionalLanguageTierCategoryLengthRule(maxLength: 86400),
            ]
        )
    }
}
