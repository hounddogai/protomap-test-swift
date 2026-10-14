import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal eligibility estimate must pass. Check returns its problems, or none.
    protocol SeasonalEligibilityEstimateRule {
        func check(_ item: SeasonalEligibilityEstimate) -> [String]
    }

    final class SeasonalEligibilityEstimateRequiredLabelRule: SeasonalEligibilityEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalEligibilityEstimate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalEligibilityEstimateAllowedCodeRule: SeasonalEligibilityEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalEligibilityEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class SeasonalEligibilityEstimateCodeLengthRule: SeasonalEligibilityEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalEligibilityEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalEligibilityEstimateTitleLengthRule: SeasonalEligibilityEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalEligibilityEstimate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalEligibilityEstimateLabelLengthRule: SeasonalEligibilityEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalEligibilityEstimate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal eligibility estimate.
    final class SeasonalEligibilityEstimateValidator {
        var rules: [any SeasonalEligibilityEstimateRule]

        init(rules: [any SeasonalEligibilityEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalEligibilityEstimate) -> [String] {
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

        func requireValid(_ item: SeasonalEligibilityEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalEligibilityEstimate]) -> [String: [String]] {
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

    static func defaultSeasonalEligibilityEstimateValidator() -> SeasonalEligibilityEstimateValidator {
        return SeasonalEligibilityEstimateValidator(
            rules: [
                SeasonalEligibilityEstimateRequiredLabelRule(message: "seasonal eligibility estimate needs a value"),
                SeasonalEligibilityEstimateAllowedCodeRule(allowed: ["legacy", "tiered"]),
                SeasonalEligibilityEstimateCodeLengthRule(maxLength: 3600),
                SeasonalEligibilityEstimateTitleLengthRule(maxLength: 120),
                SeasonalEligibilityEstimateLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
