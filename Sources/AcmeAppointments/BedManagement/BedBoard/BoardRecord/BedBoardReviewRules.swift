import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board review must pass. Check returns its problems, or none.
    protocol BedBoardReviewRule {
        func check(_ item: BedBoardReview) -> [String]
    }

    final class BedBoardReviewCodeLengthRule: BedBoardReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardReviewAmountRangeRule: BedBoardReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardReview) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardReviewDescriptionLengthRule: BedBoardReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardReview) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardReviewAllowedCodeRule: BedBoardReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BedBoardReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class BedBoardReviewVersionRangeRule: BedBoardReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardReview) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board review.
    final class BedBoardReviewValidator {
        var rules: [any BedBoardReviewRule]

        init(rules: [any BedBoardReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardReview) -> [String] {
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

        func requireValid(_ item: BedBoardReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardReview]) -> [String: [String]] {
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

    static func defaultBedBoardReviewValidator() -> BedBoardReviewValidator {
        return BedBoardReviewValidator(
            rules: [
                BedBoardReviewCodeLengthRule(maxLength: 255),
                BedBoardReviewAmountRangeRule(min: 2.3, max: 2325.2),
                BedBoardReviewDescriptionLengthRule(maxLength: 1000),
                BedBoardReviewAllowedCodeRule(allowed: ["scheduled", "capped", "regional"]),
                BedBoardReviewVersionRangeRule(min: 16, max: 86400),
            ]
        )
    }
}
