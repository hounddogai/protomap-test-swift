import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set review must pass. Check returns its problems, or none.
    protocol OrderSetReviewRule {
        func check(_ item: OrderSetReview) -> [String]
    }

    final class OrderSetReviewRequiredLabelRule: OrderSetReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetReviewCopayRangeRule: OrderSetReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetReview) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OrderSetReviewRequiredPayerRule: OrderSetReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetReview) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetReviewCodePrefixRule: OrderSetReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OrderSetReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set review.
    final class OrderSetReviewValidator {
        var rules: [any OrderSetReviewRule]

        init(rules: [any OrderSetReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetReview]) -> [String: [String]] {
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

    static func defaultOrderSetReviewValidator() -> OrderSetReviewValidator {
        return OrderSetReviewValidator(
            rules: [
                OrderSetReviewRequiredLabelRule(message: "order set review needs a value"),
                OrderSetReviewCopayRangeRule(min: 4.6, max: 1286.5),
                OrderSetReviewRequiredPayerRule(message: "order set review needs a value"),
                OrderSetReviewCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
