import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal consent form window must pass. Check returns its problems, or none.
    protocol SeasonalConsentFormWindowRule {
        func check(_ item: SeasonalConsentFormWindow) -> [String]
    }

    final class SeasonalConsentFormWindowPayerLengthRule: SeasonalConsentFormWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalConsentFormWindow) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalConsentFormWindowCodePrefixRule: SeasonalConsentFormWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalConsentFormWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalConsentFormWindowTitleLengthRule: SeasonalConsentFormWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalConsentFormWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalConsentFormWindowLimitRangeRule: SeasonalConsentFormWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalConsentFormWindow) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalConsentFormWindowAllowedTitleRule: SeasonalConsentFormWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalConsentFormWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal consent form window.
    final class SeasonalConsentFormWindowValidator {
        var rules: [any SeasonalConsentFormWindowRule]

        init(rules: [any SeasonalConsentFormWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalConsentFormWindow) -> [String] {
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

        func requireValid(_ item: SeasonalConsentFormWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalConsentFormWindow]) -> [String: [String]] {
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

    static func defaultSeasonalConsentFormWindowValidator() -> SeasonalConsentFormWindowValidator {
        return SeasonalConsentFormWindowValidator(
            rules: [
                SeasonalConsentFormWindowPayerLengthRule(maxLength: 120),
                SeasonalConsentFormWindowCodePrefixRule(prefix: "REF"),
                SeasonalConsentFormWindowTitleLengthRule(maxLength: 1000),
                SeasonalConsentFormWindowLimitRangeRule(min: 32, max: 120),
                SeasonalConsentFormWindowAllowedTitleRule(allowed: []),
            ]
        )
    }
}
