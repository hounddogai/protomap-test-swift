import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled accession preference must pass. Check returns its problems, or none.
    protocol ScheduledAccessionPreferenceRule {
        func check(_ item: ScheduledAccessionPreference) -> [String]
    }

    final class ScheduledAccessionPreferenceTitleLengthRule: ScheduledAccessionPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAccessionPreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledAccessionPreferenceCodePrefixRule: ScheduledAccessionPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledAccessionPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledAccessionPreferenceCodeLengthRule: ScheduledAccessionPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAccessionPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled accession preference.
    final class ScheduledAccessionPreferenceValidator {
        var rules: [any ScheduledAccessionPreferenceRule]

        init(rules: [any ScheduledAccessionPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAccessionPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledAccessionPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAccessionPreference]) -> [String: [String]] {
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

    static func defaultScheduledAccessionPreferenceValidator() -> ScheduledAccessionPreferenceValidator {
        return ScheduledAccessionPreferenceValidator(
            rules: [
                ScheduledAccessionPreferenceTitleLengthRule(maxLength: 1000),
                ScheduledAccessionPreferenceCodePrefixRule(prefix: "REF"),
                ScheduledAccessionPreferenceCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
