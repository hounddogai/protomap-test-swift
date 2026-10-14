import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal worklist preference must pass. Check returns its problems, or none.
    protocol SeasonalWorklistPreferenceRule {
        func check(_ item: SeasonalWorklistPreference) -> [String]
    }

    final class SeasonalWorklistPreferenceRequiredCodeRule: SeasonalWorklistPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalWorklistPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalWorklistPreferenceCodePrefixRule: SeasonalWorklistPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalWorklistPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalWorklistPreferenceTitleLengthRule: SeasonalWorklistPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalWorklistPreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalWorklistPreferenceRequiredProcedureCodeRule: SeasonalWorklistPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalWorklistPreference) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalWorklistPreferenceRequiredChannelRule: SeasonalWorklistPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalWorklistPreference) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalWorklistPreferenceArchivedGuardRule: SeasonalWorklistPreferenceRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SeasonalWorklistPreference) -> [String] {
            if item.archived && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal worklist preference.
    final class SeasonalWorklistPreferenceValidator {
        var rules: [any SeasonalWorklistPreferenceRule]

        init(rules: [any SeasonalWorklistPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalWorklistPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalWorklistPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalWorklistPreference]) -> [String: [String]] {
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

    static func defaultSeasonalWorklistPreferenceValidator() -> SeasonalWorklistPreferenceValidator {
        return SeasonalWorklistPreferenceValidator(
            rules: [
                SeasonalWorklistPreferenceRequiredCodeRule(message: "seasonal worklist preference needs a value"),
                SeasonalWorklistPreferenceCodePrefixRule(prefix: "OPS"),
                SeasonalWorklistPreferenceTitleLengthRule(maxLength: 64),
                SeasonalWorklistPreferenceRequiredProcedureCodeRule(
                    message: "seasonal worklist preference needs an entry"
                ),
                SeasonalWorklistPreferenceRequiredChannelRule(
                    message: "seasonal worklist preference needs this field"
                ),
                SeasonalWorklistPreferenceArchivedGuardRule(limit: 86400),
            ]
        )
    }
}
