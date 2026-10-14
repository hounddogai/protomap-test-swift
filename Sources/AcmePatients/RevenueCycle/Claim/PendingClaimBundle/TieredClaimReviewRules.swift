import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered claim review must pass. Check returns its problems, or none.
    protocol TieredClaimReviewRule {
        func check(_ item: TieredClaimReview) -> [String]
    }

    final class TieredClaimReviewAllowedUnitRule: TieredClaimReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredClaimReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is inconsistent"]
            }
            return []
        }
    }

    final class TieredClaimReviewCodeLengthRule: TieredClaimReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClaimReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredClaimReviewVisibleGuardRule: TieredClaimReviewRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TieredClaimReview) -> [String] {
            if item.visible && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class TieredClaimReviewUnitLengthRule: TieredClaimReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClaimReview) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredClaimReviewRequiredCodeRule: TieredClaimReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredClaimReviewOwnerIDLengthRule: TieredClaimReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClaimReview) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered claim review.
    final class TieredClaimReviewValidator {
        var rules: [any TieredClaimReviewRule]

        init(rules: [any TieredClaimReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredClaimReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredClaimReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredClaimReview]) -> [String: [String]] {
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

    static func defaultTieredClaimReviewValidator() -> TieredClaimReviewValidator {
        return TieredClaimReviewValidator(
            rules: [
                TieredClaimReviewAllowedUnitRule(allowed: []),
                TieredClaimReviewCodeLengthRule(maxLength: 64),
                TieredClaimReviewVisibleGuardRule(limit: 2.3),
                TieredClaimReviewUnitLengthRule(maxLength: 255),
                TieredClaimReviewRequiredCodeRule(message: "tiered claim review needs this field"),
                TieredClaimReviewOwnerIDLengthRule(maxLength: 255),
            ]
        )
    }
}
