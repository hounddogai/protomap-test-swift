import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted interaction digest must pass. Check returns its problems, or none.
    protocol WeightedInteractionDigestRule {
        func check(_ item: WeightedInteractionDigest) -> [String]
    }

    final class WeightedInteractionDigestCodePrefixRule: WeightedInteractionDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedInteractionDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedInteractionDigestRequiredTitleRule: WeightedInteractionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedInteractionDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedInteractionDigestVisibleGuardRule: WeightedInteractionDigestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: WeightedInteractionDigest) -> [String] {
            if item.visible && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class WeightedInteractionDigestBudgetRangeRule: WeightedInteractionDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedInteractionDigest) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted interaction digest.
    final class WeightedInteractionDigestValidator {
        var rules: [any WeightedInteractionDigestRule]

        init(rules: [any WeightedInteractionDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedInteractionDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedInteractionDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedInteractionDigest]) -> [String: [String]] {
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

    static func defaultWeightedInteractionDigestValidator() -> WeightedInteractionDigestValidator {
        return WeightedInteractionDigestValidator(
            rules: [
                WeightedInteractionDigestCodePrefixRule(prefix: "ACM"),
                WeightedInteractionDigestRequiredTitleRule(message: "weighted interaction digest needs an entry"),
                WeightedInteractionDigestVisibleGuardRule(limit: 7.4),
                WeightedInteractionDigestBudgetRangeRule(min: 6.8, max: 4794.6),
            ]
        )
    }
}
