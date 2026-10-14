import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal rounding estimate must pass. Check returns its problems, or none.
    protocol SeasonalRoundingEstimateRule {
        func check(_ item: SeasonalRoundingEstimate) -> [String]
    }

    final class SeasonalRoundingEstimateAllowedTimezoneRule: SeasonalRoundingEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalRoundingEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is inconsistent"]
            }
            return []
        }
    }

    final class SeasonalRoundingEstimateDurationMinutesRangeRule: SeasonalRoundingEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalRoundingEstimate) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalRoundingEstimateExpiresAtRangeRule: SeasonalRoundingEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalRoundingEstimate) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalRoundingEstimateCodeLengthRule: SeasonalRoundingEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalRoundingEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalRoundingEstimateRequiredDiagnosisCodeRule: SeasonalRoundingEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRoundingEstimate) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRoundingEstimateNameLengthRule: SeasonalRoundingEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalRoundingEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal rounding estimate.
    final class SeasonalRoundingEstimateValidator {
        var rules: [any SeasonalRoundingEstimateRule]

        init(rules: [any SeasonalRoundingEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalRoundingEstimate) -> [String] {
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

        func requireValid(_ item: SeasonalRoundingEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalRoundingEstimate]) -> [String: [String]] {
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

    static func defaultSeasonalRoundingEstimateValidator() -> SeasonalRoundingEstimateValidator {
        return SeasonalRoundingEstimateValidator(
            rules: [
                SeasonalRoundingEstimateAllowedTimezoneRule(allowed: ["tiered", "primary", "pending"]),
                SeasonalRoundingEstimateDurationMinutesRangeRule(min: 32, max: 80),
                SeasonalRoundingEstimateExpiresAtRangeRule(min: 80, max: 3600),
                SeasonalRoundingEstimateCodeLengthRule(maxLength: 120),
                SeasonalRoundingEstimateRequiredDiagnosisCodeRule(
                    message: "seasonal rounding estimate needs an entry"
                ),
                SeasonalRoundingEstimateNameLengthRule(maxLength: 120),
            ]
        )
    }
}
