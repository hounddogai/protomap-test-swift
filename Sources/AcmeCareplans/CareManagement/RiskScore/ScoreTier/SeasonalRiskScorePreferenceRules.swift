import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal risk score preference must pass. Check returns its problems, or none.
    protocol SeasonalRiskScorePreferenceRule {
        func check(_ item: SeasonalRiskScorePreference) -> [String]
    }

    final class SeasonalRiskScorePreferenceCodePrefixRule: SeasonalRiskScorePreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalRiskScorePreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalRiskScorePreferenceScoreRangeRule: SeasonalRiskScorePreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalRiskScorePreference) -> [String] {
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

    final class SeasonalRiskScorePreferenceTimezoneLengthRule: SeasonalRiskScorePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalRiskScorePreference) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalRiskScorePreferenceRequiredClinicianIDRule: SeasonalRiskScorePreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRiskScorePreference) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRiskScorePreferenceThresholdRangeRule: SeasonalRiskScorePreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalRiskScorePreference) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalRiskScorePreferenceCodeLengthRule: SeasonalRiskScorePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalRiskScorePreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal risk score preference.
    final class SeasonalRiskScorePreferenceValidator {
        var rules: [any SeasonalRiskScorePreferenceRule]

        init(rules: [any SeasonalRiskScorePreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalRiskScorePreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalRiskScorePreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalRiskScorePreference]) -> [String: [String]] {
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

    static func defaultSeasonalRiskScorePreferenceValidator() -> SeasonalRiskScorePreferenceValidator {
        return SeasonalRiskScorePreferenceValidator(
            rules: [
                SeasonalRiskScorePreferenceCodePrefixRule(prefix: "ACM"),
                SeasonalRiskScorePreferenceScoreRangeRule(min: 7.7, max: 780.3),
                SeasonalRiskScorePreferenceTimezoneLengthRule(maxLength: 1000),
                SeasonalRiskScorePreferenceRequiredClinicianIDRule(
                    message: "seasonal risk score preference needs this field"
                ),
                SeasonalRiskScorePreferenceThresholdRangeRule(min: 5.7, max: 4162.5),
                SeasonalRiskScorePreferenceCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
