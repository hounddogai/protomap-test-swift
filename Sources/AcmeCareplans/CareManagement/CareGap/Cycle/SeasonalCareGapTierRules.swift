import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal care gap tier must pass. Check returns its problems, or none.
    protocol SeasonalCareGapTierRule {
        func check(_ item: SeasonalCareGapTier) -> [String]
    }

    final class SeasonalCareGapTierRequiredFacilityRule: SeasonalCareGapTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCareGapTier) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCareGapTierScoreRangeRule: SeasonalCareGapTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareGapTier) -> [String] {
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

    final class SeasonalCareGapTierUnitLengthRule: SeasonalCareGapTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCareGapTier) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal care gap tier.
    final class SeasonalCareGapTierValidator {
        var rules: [any SeasonalCareGapTierRule]

        init(rules: [any SeasonalCareGapTierRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCareGapTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalCareGapTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCareGapTier]) -> [String: [String]] {
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

    static func defaultSeasonalCareGapTierValidator() -> SeasonalCareGapTierValidator {
        return SeasonalCareGapTierValidator(
            rules: [
                SeasonalCareGapTierRequiredFacilityRule(message: "seasonal care gap tier needs this field"),
                SeasonalCareGapTierScoreRangeRule(min: 8.2, max: 470.1),
                SeasonalCareGapTierUnitLengthRule(maxLength: 64),
            ]
        )
    }
}
