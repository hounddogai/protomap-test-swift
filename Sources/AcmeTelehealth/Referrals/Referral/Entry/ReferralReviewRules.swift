import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral review must pass. Check returns its problems, or none.
    protocol ReferralReviewRule {
        func check(_ item: ReferralReview) -> [String]
    }

    final class ReferralReviewRequiredFacilityRule: ReferralReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralReview) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralReviewCodeLengthRule: ReferralReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralReviewAllowedContactEmailRule: ReferralReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is duplicated"]
            }
            return []
        }
    }

    final class ReferralReviewRequiredWardRule: ReferralReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralReview) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralReviewRequiredTitleRule: ReferralReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralReview) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralReviewCeilingRangeRule: ReferralReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralReview) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a referral review.
    final class ReferralReviewValidator {
        var rules: [any ReferralReviewRule]

        init(rules: [any ReferralReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralReview]) -> [String: [String]] {
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

    static func defaultReferralReviewValidator() -> ReferralReviewValidator {
        return ReferralReviewValidator(
            rules: [
                ReferralReviewRequiredFacilityRule(message: "referral review needs a value"),
                ReferralReviewCodeLengthRule(maxLength: 32),
                ReferralReviewAllowedContactEmailRule(allowed: ["rolling", "tiered"]),
                ReferralReviewRequiredWardRule(message: "referral review needs a value"),
                ReferralReviewRequiredTitleRule(message: "referral review needs a value"),
                ReferralReviewCeilingRangeRule(min: 4.5, max: 4474.1),
            ]
        )
    }
}
