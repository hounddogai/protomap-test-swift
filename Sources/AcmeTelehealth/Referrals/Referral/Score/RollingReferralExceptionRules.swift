import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling referral exception must pass. Check returns its problems, or none.
    protocol RollingReferralExceptionRule {
        func check(_ item: RollingReferralException) -> [String]
    }

    final class RollingReferralExceptionLimitRangeRule: RollingReferralExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingReferralException) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingReferralExceptionRequiredExternalRefRule: RollingReferralExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingReferralException) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingReferralExceptionRequiredNameRule: RollingReferralExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingReferralException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingReferralExceptionWeightRangeRule: RollingReferralExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingReferralException) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingReferralExceptionArchivedGuardRule: RollingReferralExceptionRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RollingReferralException) -> [String] {
            if item.archived && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling referral exception.
    final class RollingReferralExceptionValidator {
        var rules: [any RollingReferralExceptionRule]

        init(rules: [any RollingReferralExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingReferralException) -> [String] {
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

        func requireValid(_ item: RollingReferralException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingReferralException]) -> [String: [String]] {
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

    static func defaultRollingReferralExceptionValidator() -> RollingReferralExceptionValidator {
        return RollingReferralExceptionValidator(
            rules: [
                RollingReferralExceptionLimitRangeRule(min: 80, max: 120),
                RollingReferralExceptionRequiredExternalRefRule(message: "rolling referral exception needs an entry"),
                RollingReferralExceptionRequiredNameRule(message: "rolling referral exception needs an entry"),
                RollingReferralExceptionWeightRangeRule(min: 2.9, max: 746.9),
                RollingReferralExceptionArchivedGuardRule(limit: 8.4),
            ]
        )
    }
}
