import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive referral summary must pass. Check returns its problems, or none.
    protocol AdaptiveReferralSummaryRule {
        func check(_ item: AdaptiveReferralSummary) -> [String]
    }

    final class AdaptiveReferralSummaryCodeLengthRule: AdaptiveReferralSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveReferralSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveReferralSummaryRequiredCodeRule: AdaptiveReferralSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveReferralSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveReferralSummaryWardLengthRule: AdaptiveReferralSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveReferralSummary) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive referral summary.
    final class AdaptiveReferralSummaryValidator {
        var rules: [any AdaptiveReferralSummaryRule]

        init(rules: [any AdaptiveReferralSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveReferralSummary) -> [String] {
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

        func requireValid(_ item: AdaptiveReferralSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveReferralSummary]) -> [String: [String]] {
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

    static func defaultAdaptiveReferralSummaryValidator() -> AdaptiveReferralSummaryValidator {
        return AdaptiveReferralSummaryValidator(
            rules: [
                AdaptiveReferralSummaryCodeLengthRule(maxLength: 120),
                AdaptiveReferralSummaryRequiredCodeRule(message: "adaptive referral summary needs an entry"),
                AdaptiveReferralSummaryWardLengthRule(maxLength: 32),
            ]
        )
    }
}
