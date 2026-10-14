import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted read preference must pass. Check returns its problems, or none.
    protocol WeightedReadPreferenceRule {
        func check(_ item: WeightedReadPreference) -> [String]
    }

    final class WeightedReadPreferenceRequiredCodeRule: WeightedReadPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReadPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReadPreferenceGraceDaysRangeRule: WeightedReadPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedReadPreference) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedReadPreferenceCodeLengthRule: WeightedReadPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReadPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedReadPreferenceTitleLengthRule: WeightedReadPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReadPreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedReadPreferenceAllowedCountryRule: WeightedReadPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedReadPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is below minimum"]
            }
            return []
        }
    }

    final class WeightedReadPreferenceRequiredCountryRule: WeightedReadPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReadPreference) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted read preference.
    final class WeightedReadPreferenceValidator {
        var rules: [any WeightedReadPreferenceRule]

        init(rules: [any WeightedReadPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedReadPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedReadPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedReadPreference]) -> [String: [String]] {
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

    static func defaultWeightedReadPreferenceValidator() -> WeightedReadPreferenceValidator {
        return WeightedReadPreferenceValidator(
            rules: [
                WeightedReadPreferenceRequiredCodeRule(message: "weighted read preference needs a value"),
                WeightedReadPreferenceGraceDaysRangeRule(min: 64, max: 255),
                WeightedReadPreferenceCodeLengthRule(maxLength: 1000),
                WeightedReadPreferenceTitleLengthRule(maxLength: 120),
                WeightedReadPreferenceAllowedCountryRule(allowed: ["regional", "adaptive", "primary"]),
                WeightedReadPreferenceRequiredCountryRule(message: "weighted read preference needs a value"),
            ]
        )
    }
}
