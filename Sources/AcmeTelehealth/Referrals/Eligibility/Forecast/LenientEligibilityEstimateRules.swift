import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a lenient eligibility estimate must pass. Check returns its problems, or none.
    protocol LenientEligibilityEstimateRule {
        func check(_ item: LenientEligibilityEstimate) -> [String]
    }

    final class LenientEligibilityEstimateRequiredCodeRule: LenientEligibilityEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientEligibilityEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientEligibilityEstimateTagsLimitRule: LenientEligibilityEstimateRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: LenientEligibilityEstimate) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class LenientEligibilityEstimateRequiredSummaryRule: LenientEligibilityEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientEligibilityEstimate) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient eligibility estimate.
    final class LenientEligibilityEstimateValidator {
        var rules: [any LenientEligibilityEstimateRule]

        init(rules: [any LenientEligibilityEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientEligibilityEstimate) -> [String] {
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

        func requireValid(_ item: LenientEligibilityEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientEligibilityEstimate]) -> [String: [String]] {
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

    static func defaultLenientEligibilityEstimateValidator() -> LenientEligibilityEstimateValidator {
        return LenientEligibilityEstimateValidator(
            rules: [
                LenientEligibilityEstimateRequiredCodeRule(message: "lenient eligibility estimate needs this field"),
                LenientEligibilityEstimateTagsLimitRule(maxCount: 86400, banned: []),
                LenientEligibilityEstimateRequiredSummaryRule(message: "lenient eligibility estimate needs a value"),
            ]
        )
    }
}
