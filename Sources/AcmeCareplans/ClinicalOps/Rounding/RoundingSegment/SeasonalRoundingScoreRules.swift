import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal rounding score must pass. Check returns its problems, or none.
    protocol SeasonalRoundingScoreRule {
        func check(_ item: SeasonalRoundingScore) -> [String]
    }

    final class SeasonalRoundingScoreScoreRangeRule: SeasonalRoundingScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalRoundingScore) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalRoundingScoreClinicianIDLengthRule: SeasonalRoundingScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalRoundingScore) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalRoundingScoreOwnerIDLengthRule: SeasonalRoundingScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalRoundingScore) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal rounding score.
    final class SeasonalRoundingScoreValidator {
        var rules: [any SeasonalRoundingScoreRule]

        init(rules: [any SeasonalRoundingScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalRoundingScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalRoundingScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalRoundingScore]) -> [String: [String]] {
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

    static func defaultSeasonalRoundingScoreValidator() -> SeasonalRoundingScoreValidator {
        return SeasonalRoundingScoreValidator(
            rules: [
                SeasonalRoundingScoreScoreRangeRule(min: 1.8, max: 1343.1),
                SeasonalRoundingScoreClinicianIDLengthRule(maxLength: 3600),
                SeasonalRoundingScoreOwnerIDLengthRule(maxLength: 3600),
            ]
        )
    }
}
