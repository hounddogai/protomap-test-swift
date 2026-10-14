import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral adjustment must pass. Check returns its problems, or none.
    protocol ReferralAdjustmentRule {
        func check(_ item: ReferralAdjustment) -> [String]
    }

    final class ReferralAdjustmentNameLengthRule: ReferralAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralAdjustment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralAdjustmentRequiredCodeRule: ReferralAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralAdjustmentPinnedGuardRule: ReferralAdjustmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ReferralAdjustment) -> [String] {
            if item.pinned && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a referral adjustment.
    final class ReferralAdjustmentValidator {
        var rules: [any ReferralAdjustmentRule]

        init(rules: [any ReferralAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralAdjustment) -> [String] {
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

        func requireValid(_ item: ReferralAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralAdjustment]) -> [String: [String]] {
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

    static func defaultReferralAdjustmentValidator() -> ReferralAdjustmentValidator {
        return ReferralAdjustmentValidator(
            rules: [
                ReferralAdjustmentNameLengthRule(maxLength: 1000),
                ReferralAdjustmentRequiredCodeRule(message: "referral adjustment needs this field"),
                ReferralAdjustmentPinnedGuardRule(limit: 120),
            ]
        )
    }
}
