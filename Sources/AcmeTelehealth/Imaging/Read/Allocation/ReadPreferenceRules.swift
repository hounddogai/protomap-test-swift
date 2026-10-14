import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read preference must pass. Check returns its problems, or none.
    protocol ReadPreferenceRule {
        func check(_ item: ReadPreference) -> [String]
    }

    final class ReadPreferenceCopayRangeRule: ReadPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadPreference) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReadPreferenceRequiredLabelRule: ReadPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadPreferenceLabelLengthRule: ReadPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadPreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a read preference.
    final class ReadPreferenceValidator {
        var rules: [any ReadPreferenceRule]

        init(rules: [any ReadPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadPreference) -> [String] {
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

        func requireValid(_ item: ReadPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadPreference]) -> [String: [String]] {
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

    static func defaultReadPreferenceValidator() -> ReadPreferenceValidator {
        return ReadPreferenceValidator(
            rules: [
                ReadPreferenceCopayRangeRule(min: 5.0, max: 3786.9),
                ReadPreferenceRequiredLabelRule(message: "read preference needs this field"),
                ReadPreferenceLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
