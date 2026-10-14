import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral slot must pass. Check returns its problems, or none.
    protocol ReferralSlotRule {
        func check(_ item: ReferralSlot) -> [String]
    }

    final class ReferralSlotScoreRangeRule: ReferralSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralSlot) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferralSlotRequiredCodeRule: ReferralSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralSlotCodeLengthRule: ReferralSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralSlotTagsLimitRule: ReferralSlotRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ReferralSlot) -> [String] {
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

    /// Runs every rule of a referral slot.
    final class ReferralSlotValidator {
        var rules: [any ReferralSlotRule]

        init(rules: [any ReferralSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralSlot]) -> [String: [String]] {
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

    static func defaultReferralSlotValidator() -> ReferralSlotValidator {
        return ReferralSlotValidator(
            rules: [
                ReferralSlotScoreRangeRule(min: 9.6, max: 3136.7),
                ReferralSlotRequiredCodeRule(message: "referral slot needs a value"),
                ReferralSlotCodeLengthRule(maxLength: 255),
                ReferralSlotTagsLimitRule(maxCount: 16, banned: []),
            ]
        )
    }
}
