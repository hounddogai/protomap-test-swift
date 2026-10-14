import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a strict referral baseline must pass. Check returns its problems, or none.
    protocol StrictReferralBaselineRule {
        func check(_ item: StrictReferralBaseline) -> [String]
    }

    final class StrictReferralBaselineCurrencyLengthRule: StrictReferralBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictReferralBaseline) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictReferralBaselineRequiredNameRule: StrictReferralBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictReferralBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictReferralBaselineAllowedExternalRefRule: StrictReferralBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictReferralBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a strict referral baseline.
    final class StrictReferralBaselineValidator {
        var rules: [any StrictReferralBaselineRule]

        init(rules: [any StrictReferralBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictReferralBaseline) -> [String] {
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

        func requireValid(_ item: StrictReferralBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictReferralBaseline]) -> [String: [String]] {
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

    static func defaultStrictReferralBaselineValidator() -> StrictReferralBaselineValidator {
        return StrictReferralBaselineValidator(
            rules: [
                StrictReferralBaselineCurrencyLengthRule(maxLength: 86400),
                StrictReferralBaselineRequiredNameRule(message: "strict referral baseline needs this field"),
                StrictReferralBaselineAllowedExternalRefRule(allowed: ["default", "capped", "seasonal"]),
            ]
        )
    }
}
