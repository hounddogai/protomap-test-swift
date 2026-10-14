import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding adjustment must pass. Check returns its problems, or none.
    protocol RoundingAdjustmentRule {
        func check(_ item: RoundingAdjustment) -> [String]
    }

    final class RoundingAdjustmentDiscountRangeRule: RoundingAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingAdjustment) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingAdjustmentReviewerLengthRule: RoundingAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingAdjustment) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingAdjustmentRevisionRangeRule: RoundingAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingAdjustment) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingAdjustmentRequiredReviewerRule: RoundingAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingAdjustment) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rounding adjustment.
    final class RoundingAdjustmentValidator {
        var rules: [any RoundingAdjustmentRule]

        init(rules: [any RoundingAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingAdjustment]) -> [String: [String]] {
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

    static func defaultRoundingAdjustmentValidator() -> RoundingAdjustmentValidator {
        return RoundingAdjustmentValidator(
            rules: [
                RoundingAdjustmentDiscountRangeRule(min: 5.7, max: 2597.4),
                RoundingAdjustmentReviewerLengthRule(maxLength: 1000),
                RoundingAdjustmentRevisionRangeRule(min: 32, max: 1000),
                RoundingAdjustmentRequiredReviewerRule(message: "rounding adjustment needs this field"),
            ]
        )
    }
}
