import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy bed board review must pass. Check returns its problems, or none.
    protocol LegacyBedBoardReviewRule {
        func check(_ item: LegacyBedBoardReview) -> [String]
    }

    final class LegacyBedBoardReviewActiveGuardRule: LegacyBedBoardReviewRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LegacyBedBoardReview) -> [String] {
            if item.active && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class LegacyBedBoardReviewMarginRangeRule: LegacyBedBoardReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyBedBoardReview) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyBedBoardReviewSegmentLengthRule: LegacyBedBoardReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyBedBoardReview) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy bed board review.
    final class LegacyBedBoardReviewValidator {
        var rules: [any LegacyBedBoardReviewRule]

        init(rules: [any LegacyBedBoardReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyBedBoardReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyBedBoardReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyBedBoardReview]) -> [String: [String]] {
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

    static func defaultLegacyBedBoardReviewValidator() -> LegacyBedBoardReviewValidator {
        return LegacyBedBoardReviewValidator(
            rules: [
                LegacyBedBoardReviewActiveGuardRule(limit: 32),
                LegacyBedBoardReviewMarginRangeRule(min: 7.9, max: 3701.0),
                LegacyBedBoardReviewSegmentLengthRule(maxLength: 3600),
            ]
        )
    }
}
