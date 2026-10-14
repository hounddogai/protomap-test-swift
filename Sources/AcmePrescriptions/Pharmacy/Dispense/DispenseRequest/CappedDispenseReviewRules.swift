import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped dispense review must pass. Check returns its problems, or none.
    protocol CappedDispenseReviewRule {
        func check(_ item: CappedDispenseReview) -> [String]
    }

    final class CappedDispenseReviewCodePrefixRule: CappedDispenseReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedDispenseReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedDispenseReviewPriorityRangeRule: CappedDispenseReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedDispenseReview) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedDispenseReviewRequiredLabelRule: CappedDispenseReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDispenseReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped dispense review.
    final class CappedDispenseReviewValidator {
        var rules: [any CappedDispenseReviewRule]

        init(rules: [any CappedDispenseReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedDispenseReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedDispenseReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedDispenseReview]) -> [String: [String]] {
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

    static func defaultCappedDispenseReviewValidator() -> CappedDispenseReviewValidator {
        return CappedDispenseReviewValidator(
            rules: [
                CappedDispenseReviewCodePrefixRule(prefix: "X"),
                CappedDispenseReviewPriorityRangeRule(min: 32, max: 3600),
                CappedDispenseReviewRequiredLabelRule(message: "capped dispense review needs an entry"),
            ]
        )
    }
}
