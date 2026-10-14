import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach review must pass. Check returns its problems, or none.
    protocol OutreachReviewRule {
        func check(_ item: OutreachReview) -> [String]
    }

    final class OutreachReviewRefillsRangeRule: OutreachReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachReview) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OutreachReviewRequiredCodeRule: OutreachReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachReviewAllowedCountryRule: OutreachReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OutreachReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is blocked"]
            }
            return []
        }
    }

    final class OutreachReviewPinnedGuardRule: OutreachReviewRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: OutreachReview) -> [String] {
            if item.pinned && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class OutreachReviewRevisionRangeRule: OutreachReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachReview) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachReviewUpdatedAtRangeRule: OutreachReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachReview) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a outreach review.
    final class OutreachReviewValidator {
        var rules: [any OutreachReviewRule]

        init(rules: [any OutreachReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachReview]) -> [String: [String]] {
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

    static func defaultOutreachReviewValidator() -> OutreachReviewValidator {
        return OutreachReviewValidator(
            rules: [
                OutreachReviewRefillsRangeRule(min: 80, max: 120),
                OutreachReviewRequiredCodeRule(message: "outreach review needs this field"),
                OutreachReviewAllowedCountryRule(allowed: []),
                OutreachReviewPinnedGuardRule(limit: 1000),
                OutreachReviewRevisionRangeRule(min: 120, max: 86400),
                OutreachReviewUpdatedAtRangeRule(min: 16, max: 86400),
            ]
        )
    }
}
