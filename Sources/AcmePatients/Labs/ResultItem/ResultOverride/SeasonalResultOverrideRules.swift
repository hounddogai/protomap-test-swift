import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal result override must pass. Check returns its problems, or none.
    protocol SeasonalResultOverrideRule {
        func check(_ item: SeasonalResultOverride) -> [String]
    }

    final class SeasonalResultOverrideFacilityLengthRule: SeasonalResultOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalResultOverride) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalResultOverrideRequiredSummaryRule: SeasonalResultOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalResultOverride) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalResultOverrideCodeLengthRule: SeasonalResultOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalResultOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalResultOverrideTitleLengthRule: SeasonalResultOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalResultOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalResultOverrideCodePrefixRule: SeasonalResultOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalResultOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalResultOverrideRequiredFacilityRule: SeasonalResultOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalResultOverride) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal result override.
    final class SeasonalResultOverrideValidator {
        var rules: [any SeasonalResultOverrideRule]

        init(rules: [any SeasonalResultOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalResultOverride) -> [String] {
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

        func requireValid(_ item: SeasonalResultOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalResultOverride]) -> [String: [String]] {
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

    static func defaultSeasonalResultOverrideValidator() -> SeasonalResultOverrideValidator {
        return SeasonalResultOverrideValidator(
            rules: [
                SeasonalResultOverrideFacilityLengthRule(maxLength: 255),
                SeasonalResultOverrideRequiredSummaryRule(message: "seasonal result override needs an entry"),
                SeasonalResultOverrideCodeLengthRule(maxLength: 32),
                SeasonalResultOverrideTitleLengthRule(maxLength: 1000),
                SeasonalResultOverrideCodePrefixRule(prefix: "Q"),
                SeasonalResultOverrideRequiredFacilityRule(message: "seasonal result override needs this field"),
            ]
        )
    }
}
