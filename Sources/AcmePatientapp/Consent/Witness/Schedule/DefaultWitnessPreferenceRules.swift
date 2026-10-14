import AcmePlatform
import Foundation

extension Consent {
    /// A rule a default witness preference must pass. Check returns its problems, or none.
    protocol DefaultWitnessPreferenceRule {
        func check(_ item: DefaultWitnessPreference) -> [String]
    }

    final class DefaultWitnessPreferenceAttemptsRangeRule: DefaultWitnessPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultWitnessPreference) -> [String] {
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

    final class DefaultWitnessPreferenceReviewerLengthRule: DefaultWitnessPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultWitnessPreference) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultWitnessPreferenceVersionRangeRule: DefaultWitnessPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultWitnessPreference) -> [String] {
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

    /// Runs every rule of a default witness preference.
    final class DefaultWitnessPreferenceValidator {
        var rules: [any DefaultWitnessPreferenceRule]

        init(rules: [any DefaultWitnessPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultWitnessPreference) -> [String] {
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

        func requireValid(_ item: DefaultWitnessPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultWitnessPreference]) -> [String: [String]] {
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

    static func defaultDefaultWitnessPreferenceValidator() -> DefaultWitnessPreferenceValidator {
        return DefaultWitnessPreferenceValidator(
            rules: [
                DefaultWitnessPreferenceAttemptsRangeRule(min: 120, max: 120),
                DefaultWitnessPreferenceReviewerLengthRule(maxLength: 120),
                DefaultWitnessPreferenceVersionRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
