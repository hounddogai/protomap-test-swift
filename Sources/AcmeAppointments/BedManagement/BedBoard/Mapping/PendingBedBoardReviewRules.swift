import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending bed board review must pass. Check returns its problems, or none.
    protocol PendingBedBoardReviewRule {
        func check(_ item: PendingBedBoardReview) -> [String]
    }

    final class PendingBedBoardReviewAmountRangeRule: PendingBedBoardReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingBedBoardReview) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingBedBoardReviewRequiredLabelRule: PendingBedBoardReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingBedBoardReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingBedBoardReviewActiveGuardRule: PendingBedBoardReviewRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PendingBedBoardReview) -> [String] {
            if item.active && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class PendingBedBoardReviewCodeLengthRule: PendingBedBoardReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingBedBoardReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingBedBoardReviewRequiredChecksumRule: PendingBedBoardReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingBedBoardReview) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending bed board review.
    final class PendingBedBoardReviewValidator {
        var rules: [any PendingBedBoardReviewRule]

        init(rules: [any PendingBedBoardReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingBedBoardReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingBedBoardReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingBedBoardReview]) -> [String: [String]] {
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

    static func defaultPendingBedBoardReviewValidator() -> PendingBedBoardReviewValidator {
        return PendingBedBoardReviewValidator(
            rules: [
                PendingBedBoardReviewAmountRangeRule(min: 7.2, max: 2728.1),
                PendingBedBoardReviewRequiredLabelRule(message: "pending bed board review needs an entry"),
                PendingBedBoardReviewActiveGuardRule(limit: 120),
                PendingBedBoardReviewCodeLengthRule(maxLength: 32),
                PendingBedBoardReviewRequiredChecksumRule(message: "pending bed board review needs a value"),
            ]
        )
    }
}
