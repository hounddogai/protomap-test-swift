import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary modality review must pass. Check returns its problems, or none.
    protocol PrimaryModalityReviewRule {
        func check(_ item: PrimaryModalityReview) -> [String]
    }

    final class PrimaryModalityReviewRequiredCodeRule: PrimaryModalityReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryModalityReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryModalityReviewWeightRangeRule: PrimaryModalityReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryModalityReview) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryModalityReviewAllergyLengthRule: PrimaryModalityReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryModalityReview) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryModalityReviewRequiredTitleRule: PrimaryModalityReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryModalityReview) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryModalityReviewPinnedGuardRule: PrimaryModalityReviewRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PrimaryModalityReview) -> [String] {
            if item.pinned && (item.weight > limit) {
                return ["weight \(item.weight) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class PrimaryModalityReviewCostRangeRule: PrimaryModalityReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryModalityReview) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary modality review.
    final class PrimaryModalityReviewValidator {
        var rules: [any PrimaryModalityReviewRule]

        init(rules: [any PrimaryModalityReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryModalityReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryModalityReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryModalityReview]) -> [String: [String]] {
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

    static func defaultPrimaryModalityReviewValidator() -> PrimaryModalityReviewValidator {
        return PrimaryModalityReviewValidator(
            rules: [
                PrimaryModalityReviewRequiredCodeRule(message: "primary modality review needs a value"),
                PrimaryModalityReviewWeightRangeRule(min: 3.3, max: 63.5),
                PrimaryModalityReviewAllergyLengthRule(maxLength: 255),
                PrimaryModalityReviewRequiredTitleRule(message: "primary modality review needs this field"),
                PrimaryModalityReviewPinnedGuardRule(limit: 8.7),
                PrimaryModalityReviewCostRangeRule(min: 3.1, max: 2020.0),
            ]
        )
    }
}
