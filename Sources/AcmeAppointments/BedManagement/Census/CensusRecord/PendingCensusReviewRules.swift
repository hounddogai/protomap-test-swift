import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending census review must pass. Check returns its problems, or none.
    protocol PendingCensusReviewRule {
        func check(_ item: PendingCensusReview) -> [String]
    }

    final class PendingCensusReviewUnitLengthRule: PendingCensusReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCensusReview) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCensusReviewRequiredLabelRule: PendingCensusReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCensusReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCensusReviewRequiredTitleRule: PendingCensusReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCensusReview) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCensusReviewScoreRangeRule: PendingCensusReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCensusReview) -> [String] {
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

    final class PendingCensusReviewCostRangeRule: PendingCensusReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCensusReview) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a pending census review.
    final class PendingCensusReviewValidator {
        var rules: [any PendingCensusReviewRule]

        init(rules: [any PendingCensusReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCensusReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingCensusReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCensusReview]) -> [String: [String]] {
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

    static func defaultPendingCensusReviewValidator() -> PendingCensusReviewValidator {
        return PendingCensusReviewValidator(
            rules: [
                PendingCensusReviewUnitLengthRule(maxLength: 1000),
                PendingCensusReviewRequiredLabelRule(message: "pending census review needs a value"),
                PendingCensusReviewRequiredTitleRule(message: "pending census review needs a value"),
                PendingCensusReviewScoreRangeRule(min: 7.3, max: 2862.3),
                PendingCensusReviewCostRangeRule(min: 9.1, max: 3860.2),
            ]
        )
    }
}
