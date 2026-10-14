import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral request must pass. Check returns its problems, or none.
    protocol ReferralRequestRule {
        func check(_ item: ReferralRequest) -> [String]
    }

    final class ReferralRequestAllowedCodeRule: ReferralRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class ReferralRequestBedLengthRule: ReferralRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralRequest) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralRequestRequiredBedRule: ReferralRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralRequest) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralRequestAcuityRangeRule: ReferralRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralRequest) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferralRequestTitleLengthRule: ReferralRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralRequestRatioRangeRule: ReferralRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralRequest) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a referral request.
    final class ReferralRequestValidator {
        var rules: [any ReferralRequestRule]

        init(rules: [any ReferralRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralRequest]) -> [String: [String]] {
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

    static func defaultReferralRequestValidator() -> ReferralRequestValidator {
        return ReferralRequestValidator(
            rules: [
                ReferralRequestAllowedCodeRule(allowed: ["capped", "strict"]),
                ReferralRequestBedLengthRule(maxLength: 86400),
                ReferralRequestRequiredBedRule(message: "referral request needs an entry"),
                ReferralRequestAcuityRangeRule(min: 16, max: 3600),
                ReferralRequestTitleLengthRule(maxLength: 255),
                ReferralRequestRatioRangeRule(min: 3.8, max: 4566.4),
            ]
        )
    }
}
