import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted goal digest must pass. Check returns its problems, or none.
    protocol WeightedGoalDigestRule {
        func check(_ item: WeightedGoalDigest) -> [String]
    }

    final class WeightedGoalDigestReviewerLengthRule: WeightedGoalDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedGoalDigest) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedGoalDigestRequiredNameRule: WeightedGoalDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedGoalDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedGoalDigestRequiredSourceRule: WeightedGoalDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedGoalDigest) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedGoalDigestSourceLengthRule: WeightedGoalDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedGoalDigest) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedGoalDigestQuantityRangeRule: WeightedGoalDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedGoalDigest) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedGoalDigestRequiredReviewerRule: WeightedGoalDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedGoalDigest) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted goal digest.
    final class WeightedGoalDigestValidator {
        var rules: [any WeightedGoalDigestRule]

        init(rules: [any WeightedGoalDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedGoalDigest) -> [String] {
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

        func requireValid(_ item: WeightedGoalDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedGoalDigest]) -> [String: [String]] {
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

    static func defaultWeightedGoalDigestValidator() -> WeightedGoalDigestValidator {
        return WeightedGoalDigestValidator(
            rules: [
                WeightedGoalDigestReviewerLengthRule(maxLength: 1000),
                WeightedGoalDigestRequiredNameRule(message: "weighted goal digest needs a value"),
                WeightedGoalDigestRequiredSourceRule(message: "weighted goal digest needs this field"),
                WeightedGoalDigestSourceLengthRule(maxLength: 16),
                WeightedGoalDigestQuantityRangeRule(min: 80, max: 3600),
                WeightedGoalDigestRequiredReviewerRule(message: "weighted goal digest needs an entry"),
            ]
        )
    }
}
