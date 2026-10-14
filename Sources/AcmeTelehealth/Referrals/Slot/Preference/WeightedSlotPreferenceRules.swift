import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted slot preference must pass. Check returns its problems, or none.
    protocol WeightedSlotPreferenceRule {
        func check(_ item: WeightedSlotPreference) -> [String]
    }

    final class WeightedSlotPreferenceLocaleLengthRule: WeightedSlotPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSlotPreference) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedSlotPreferenceScoreRangeRule: WeightedSlotPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedSlotPreference) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedSlotPreferenceRequiredCodeRule: WeightedSlotPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSlotPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted slot preference.
    final class WeightedSlotPreferenceValidator {
        var rules: [any WeightedSlotPreferenceRule]

        init(rules: [any WeightedSlotPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSlotPreference) -> [String] {
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

        func requireValid(_ item: WeightedSlotPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSlotPreference]) -> [String: [String]] {
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

    static func defaultWeightedSlotPreferenceValidator() -> WeightedSlotPreferenceValidator {
        return WeightedSlotPreferenceValidator(
            rules: [
                WeightedSlotPreferenceLocaleLengthRule(maxLength: 3600),
                WeightedSlotPreferenceScoreRangeRule(min: 8.5, max: 2314.7),
                WeightedSlotPreferenceRequiredCodeRule(message: "weighted slot preference needs this field"),
            ]
        )
    }
}
