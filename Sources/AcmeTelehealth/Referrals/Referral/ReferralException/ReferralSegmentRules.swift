import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral segment must pass. Check returns its problems, or none.
    protocol ReferralSegmentRule {
        func check(_ item: ReferralSegment) -> [String]
    }

    final class ReferralSegmentAllowedNameRule: ReferralSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class ReferralSegmentCopayRangeRule: ReferralSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralSegment) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferralSegmentRequiredNameRule: ReferralSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralSegmentCodeLengthRule: ReferralSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a referral segment.
    final class ReferralSegmentValidator {
        var rules: [any ReferralSegmentRule]

        init(rules: [any ReferralSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralSegment]) -> [String: [String]] {
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

    static func defaultReferralSegmentValidator() -> ReferralSegmentValidator {
        return ReferralSegmentValidator(
            rules: [
                ReferralSegmentAllowedNameRule(allowed: ["batched"]),
                ReferralSegmentCopayRangeRule(min: 4.3, max: 2364.3),
                ReferralSegmentRequiredNameRule(message: "referral segment needs an entry"),
                ReferralSegmentCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
