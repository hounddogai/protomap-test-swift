import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted referral exception must pass. Check returns its problems, or none.
    protocol WeightedReferralExceptionRule {
        func check(_ item: WeightedReferralException) -> [String]
    }

    final class WeightedReferralExceptionAllowedTitleRule: WeightedReferralExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedReferralException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    final class WeightedReferralExceptionRefillsRangeRule: WeightedReferralExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedReferralException) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedReferralExceptionClinicianIDLengthRule: WeightedReferralExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReferralException) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedReferralExceptionTitleLengthRule: WeightedReferralExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReferralException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted referral exception.
    final class WeightedReferralExceptionValidator {
        var rules: [any WeightedReferralExceptionRule]

        init(rules: [any WeightedReferralExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedReferralException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedReferralException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedReferralException]) -> [String: [String]] {
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

    static func defaultWeightedReferralExceptionValidator() -> WeightedReferralExceptionValidator {
        return WeightedReferralExceptionValidator(
            rules: [
                WeightedReferralExceptionAllowedTitleRule(allowed: ["fallback", "batched"]),
                WeightedReferralExceptionRefillsRangeRule(min: 255, max: 1000),
                WeightedReferralExceptionClinicianIDLengthRule(maxLength: 32),
                WeightedReferralExceptionTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
