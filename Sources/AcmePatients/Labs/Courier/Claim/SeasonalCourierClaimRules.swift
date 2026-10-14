import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal courier claim must pass. Check returns its problems, or none.
    protocol SeasonalCourierClaimRule {
        func check(_ item: SeasonalCourierClaim) -> [String]
    }

    final class SeasonalCourierClaimPayerLengthRule: SeasonalCourierClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCourierClaim) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCourierClaimExpiresAtRangeRule: SeasonalCourierClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCourierClaim) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalCourierClaimRequiredPayerRule: SeasonalCourierClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCourierClaim) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCourierClaimRequiredTitleRule: SeasonalCourierClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCourierClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCourierClaimRatioRangeRule: SeasonalCourierClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCourierClaim) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal courier claim.
    final class SeasonalCourierClaimValidator {
        var rules: [any SeasonalCourierClaimRule]

        init(rules: [any SeasonalCourierClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCourierClaim) -> [String] {
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

        func requireValid(_ item: SeasonalCourierClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCourierClaim]) -> [String: [String]] {
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

    static func defaultSeasonalCourierClaimValidator() -> SeasonalCourierClaimValidator {
        return SeasonalCourierClaimValidator(
            rules: [
                SeasonalCourierClaimPayerLengthRule(maxLength: 16),
                SeasonalCourierClaimExpiresAtRangeRule(min: 120, max: 255),
                SeasonalCourierClaimRequiredPayerRule(message: "seasonal courier claim needs an entry"),
                SeasonalCourierClaimRequiredTitleRule(message: "seasonal courier claim needs this field"),
                SeasonalCourierClaimRatioRangeRule(min: 1.4, max: 2666.6),
            ]
        )
    }
}
