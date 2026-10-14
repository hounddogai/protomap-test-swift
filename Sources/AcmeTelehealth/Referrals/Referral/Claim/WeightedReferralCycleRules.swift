import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted referral cycle must pass. Check returns its problems, or none.
    protocol WeightedReferralCycleRule {
        func check(_ item: WeightedReferralCycle) -> [String]
    }

    final class WeightedReferralCycleRequiredUnitRule: WeightedReferralCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralCycle) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferralCycleTitleLengthRule: WeightedReferralCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReferralCycle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedReferralCycleRequiredTitleRule: WeightedReferralCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralCycle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferralCycleAllowedCodeRule: WeightedReferralCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedReferralCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class WeightedReferralCycleRequiredCodeRule: WeightedReferralCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferralCycleCodeLengthRule: WeightedReferralCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReferralCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted referral cycle.
    final class WeightedReferralCycleValidator {
        var rules: [any WeightedReferralCycleRule]

        init(rules: [any WeightedReferralCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedReferralCycle) -> [String] {
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

        func requireValid(_ item: WeightedReferralCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedReferralCycle]) -> [String: [String]] {
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

    static func defaultWeightedReferralCycleValidator() -> WeightedReferralCycleValidator {
        return WeightedReferralCycleValidator(
            rules: [
                WeightedReferralCycleRequiredUnitRule(message: "weighted referral cycle needs this field"),
                WeightedReferralCycleTitleLengthRule(maxLength: 120),
                WeightedReferralCycleRequiredTitleRule(message: "weighted referral cycle needs an entry"),
                WeightedReferralCycleAllowedCodeRule(allowed: ["strict"]),
                WeightedReferralCycleRequiredCodeRule(message: "weighted referral cycle needs this field"),
                WeightedReferralCycleCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
