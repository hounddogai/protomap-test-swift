import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled courier review must pass. Check returns its problems, or none.
    protocol ScheduledCourierReviewRule {
        func check(_ item: ScheduledCourierReview) -> [String]
    }

    final class ScheduledCourierReviewCodePrefixRule: ScheduledCourierReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledCourierReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledCourierReviewCeilingRangeRule: ScheduledCourierReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCourierReview) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledCourierReviewAllowedNameRule: ScheduledCourierReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledCourierReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled courier review.
    final class ScheduledCourierReviewValidator {
        var rules: [any ScheduledCourierReviewRule]

        init(rules: [any ScheduledCourierReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCourierReview) -> [String] {
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

        func requireValid(_ item: ScheduledCourierReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCourierReview]) -> [String: [String]] {
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

    static func defaultScheduledCourierReviewValidator() -> ScheduledCourierReviewValidator {
        return ScheduledCourierReviewValidator(
            rules: [
                ScheduledCourierReviewCodePrefixRule(prefix: "Q"),
                ScheduledCourierReviewCeilingRangeRule(min: 9.1, max: 777.3),
                ScheduledCourierReviewAllowedNameRule(allowed: ["weighted"]),
            ]
        )
    }
}
