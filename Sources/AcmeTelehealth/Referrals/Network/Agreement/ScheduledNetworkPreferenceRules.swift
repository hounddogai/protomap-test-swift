import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled network preference must pass. Check returns its problems, or none.
    protocol ScheduledNetworkPreferenceRule {
        func check(_ item: ScheduledNetworkPreference) -> [String]
    }

    final class ScheduledNetworkPreferenceAttemptsRangeRule: ScheduledNetworkPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledNetworkPreference) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledNetworkPreferenceCodeLengthRule: ScheduledNetworkPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledNetworkPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledNetworkPreferenceSummaryLengthRule: ScheduledNetworkPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledNetworkPreference) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledNetworkPreferenceCodePrefixRule: ScheduledNetworkPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledNetworkPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledNetworkPreferenceRequiredTitleRule: ScheduledNetworkPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledNetworkPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled network preference.
    final class ScheduledNetworkPreferenceValidator {
        var rules: [any ScheduledNetworkPreferenceRule]

        init(rules: [any ScheduledNetworkPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledNetworkPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledNetworkPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledNetworkPreference]) -> [String: [String]] {
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

    static func defaultScheduledNetworkPreferenceValidator() -> ScheduledNetworkPreferenceValidator {
        return ScheduledNetworkPreferenceValidator(
            rules: [
                ScheduledNetworkPreferenceAttemptsRangeRule(min: 80, max: 255),
                ScheduledNetworkPreferenceCodeLengthRule(maxLength: 3600),
                ScheduledNetworkPreferenceSummaryLengthRule(maxLength: 80),
                ScheduledNetworkPreferenceCodePrefixRule(prefix: "X"),
                ScheduledNetworkPreferenceRequiredTitleRule(message: "scheduled network preference needs this field"),
            ]
        )
    }
}
