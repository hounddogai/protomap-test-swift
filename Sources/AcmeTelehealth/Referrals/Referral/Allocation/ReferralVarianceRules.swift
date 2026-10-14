import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral variance must pass. Check returns its problems, or none.
    protocol ReferralVarianceRule {
        func check(_ item: ReferralVariance) -> [String]
    }

    final class ReferralVarianceQuantityRangeRule: ReferralVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralVariance) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferralVarianceRequiredProcedureCodeRule: ReferralVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralVariance) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralVarianceTitleLengthRule: ReferralVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralVarianceRequiredCodeRule: ReferralVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a referral variance.
    final class ReferralVarianceValidator {
        var rules: [any ReferralVarianceRule]

        init(rules: [any ReferralVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralVariance) -> [String] {
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

        func requireValid(_ item: ReferralVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralVariance]) -> [String: [String]] {
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

    static func defaultReferralVarianceValidator() -> ReferralVarianceValidator {
        return ReferralVarianceValidator(
            rules: [
                ReferralVarianceQuantityRangeRule(min: 64, max: 3600),
                ReferralVarianceRequiredProcedureCodeRule(message: "referral variance needs a value"),
                ReferralVarianceTitleLengthRule(maxLength: 1000),
                ReferralVarianceRequiredCodeRule(message: "referral variance needs a value"),
            ]
        )
    }
}
