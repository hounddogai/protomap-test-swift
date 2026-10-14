import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory review must pass. Check returns its problems, or none.
    protocol InventoryReviewRule {
        func check(_ item: InventoryReview) -> [String]
    }

    final class InventoryReviewCodePrefixRule: InventoryReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventoryReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InventoryReviewAttemptsRangeRule: InventoryReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryReview) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InventoryReviewCodeLengthRule: InventoryReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory review.
    final class InventoryReviewValidator {
        var rules: [any InventoryReviewRule]

        init(rules: [any InventoryReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryReview) -> [String] {
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

        func requireValid(_ item: InventoryReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryReview]) -> [String: [String]] {
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

    static func defaultInventoryReviewValidator() -> InventoryReviewValidator {
        return InventoryReviewValidator(
            rules: [
                InventoryReviewCodePrefixRule(prefix: "Q"),
                InventoryReviewAttemptsRangeRule(min: 16, max: 80),
                InventoryReviewCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
