import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up review must pass. Check returns its problems, or none.
    protocol FollowUpReviewRule {
        func check(_ item: FollowUpReview) -> [String]
    }

    final class FollowUpReviewEncounterIDLengthRule: FollowUpReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpReview) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpReviewLabelLengthRule: FollowUpReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpReviewRequiredClinicianIDRule: FollowUpReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpReview) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpReviewCodeLengthRule: FollowUpReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpReviewAllowedSpecialtyRule: FollowUpReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FollowUpReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is not allowed"]
            }
            return []
        }
    }

    final class FollowUpReviewCodePrefixRule: FollowUpReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up review.
    final class FollowUpReviewValidator {
        var rules: [any FollowUpReviewRule]

        init(rules: [any FollowUpReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpReview]) -> [String: [String]] {
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

    static func defaultFollowUpReviewValidator() -> FollowUpReviewValidator {
        return FollowUpReviewValidator(
            rules: [
                FollowUpReviewEncounterIDLengthRule(maxLength: 16),
                FollowUpReviewLabelLengthRule(maxLength: 32),
                FollowUpReviewRequiredClinicianIDRule(message: "follow up review needs this field"),
                FollowUpReviewCodeLengthRule(maxLength: 120),
                FollowUpReviewAllowedSpecialtyRule(allowed: ["batched", "seasonal"]),
                FollowUpReviewCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
