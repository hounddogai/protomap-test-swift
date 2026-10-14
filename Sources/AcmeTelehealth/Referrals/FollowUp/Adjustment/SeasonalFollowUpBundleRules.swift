import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal follow up bundle must pass. Check returns its problems, or none.
    protocol SeasonalFollowUpBundleRule {
        func check(_ item: SeasonalFollowUpBundle) -> [String]
    }

    final class SeasonalFollowUpBundleRequiredLocaleRule: SeasonalFollowUpBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalFollowUpBundle) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalFollowUpBundleRequiredSpecialtyRule: SeasonalFollowUpBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalFollowUpBundle) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalFollowUpBundleCodeLengthRule: SeasonalFollowUpBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalFollowUpBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalFollowUpBundleRequiredCodeRule: SeasonalFollowUpBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalFollowUpBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalFollowUpBundleStartsAtRangeRule: SeasonalFollowUpBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalFollowUpBundle) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalFollowUpBundleCodePrefixRule: SeasonalFollowUpBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalFollowUpBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal follow up bundle.
    final class SeasonalFollowUpBundleValidator {
        var rules: [any SeasonalFollowUpBundleRule]

        init(rules: [any SeasonalFollowUpBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalFollowUpBundle) -> [String] {
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

        func requireValid(_ item: SeasonalFollowUpBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalFollowUpBundle]) -> [String: [String]] {
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

    static func defaultSeasonalFollowUpBundleValidator() -> SeasonalFollowUpBundleValidator {
        return SeasonalFollowUpBundleValidator(
            rules: [
                SeasonalFollowUpBundleRequiredLocaleRule(message: "seasonal follow up bundle needs an entry"),
                SeasonalFollowUpBundleRequiredSpecialtyRule(message: "seasonal follow up bundle needs this field"),
                SeasonalFollowUpBundleCodeLengthRule(maxLength: 32),
                SeasonalFollowUpBundleRequiredCodeRule(message: "seasonal follow up bundle needs a value"),
                SeasonalFollowUpBundleStartsAtRangeRule(min: 120, max: 3600),
                SeasonalFollowUpBundleCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
