import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a adaptive rounding preference must pass. Check returns its problems, or none.
    protocol AdaptiveRoundingPreferenceRule {
        func check(_ item: AdaptiveRoundingPreference) -> [String]
    }

    final class AdaptiveRoundingPreferenceDurationMinutesRangeRule: AdaptiveRoundingPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRoundingPreference) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveRoundingPreferenceRequiredOwnerIDRule: AdaptiveRoundingPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRoundingPreference) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRoundingPreferenceOwnerIDLengthRule: AdaptiveRoundingPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRoundingPreference) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRoundingPreferenceRequiredSummaryRule: AdaptiveRoundingPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRoundingPreference) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive rounding preference.
    final class AdaptiveRoundingPreferenceValidator {
        var rules: [any AdaptiveRoundingPreferenceRule]

        init(rules: [any AdaptiveRoundingPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRoundingPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveRoundingPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRoundingPreference]) -> [String: [String]] {
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

    static func defaultAdaptiveRoundingPreferenceValidator() -> AdaptiveRoundingPreferenceValidator {
        return AdaptiveRoundingPreferenceValidator(
            rules: [
                AdaptiveRoundingPreferenceDurationMinutesRangeRule(min: 1000, max: 86400),
                AdaptiveRoundingPreferenceRequiredOwnerIDRule(
                    message: "adaptive rounding preference needs this field"
                ),
                AdaptiveRoundingPreferenceOwnerIDLengthRule(maxLength: 86400),
                AdaptiveRoundingPreferenceRequiredSummaryRule(message: "adaptive rounding preference needs a value"),
            ]
        )
    }
}
