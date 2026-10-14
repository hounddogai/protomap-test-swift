import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy referral entry must pass. Check returns its problems, or none.
    protocol LegacyReferralEntryRule {
        func check(_ item: LegacyReferralEntry) -> [String]
    }

    final class LegacyReferralEntryMarginRangeRule: LegacyReferralEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyReferralEntry) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyReferralEntryRequiredNameRule: LegacyReferralEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyReferralEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyReferralEntryRequiredCodeRule: LegacyReferralEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyReferralEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyReferralEntryCodePrefixRule: LegacyReferralEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyReferralEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyReferralEntryFloorValueRangeRule: LegacyReferralEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyReferralEntry) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy referral entry.
    final class LegacyReferralEntryValidator {
        var rules: [any LegacyReferralEntryRule]

        init(rules: [any LegacyReferralEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyReferralEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyReferralEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyReferralEntry]) -> [String: [String]] {
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

    static func defaultLegacyReferralEntryValidator() -> LegacyReferralEntryValidator {
        return LegacyReferralEntryValidator(
            rules: [
                LegacyReferralEntryMarginRangeRule(min: 0.1, max: 476.9),
                LegacyReferralEntryRequiredNameRule(message: "legacy referral entry needs a value"),
                LegacyReferralEntryRequiredCodeRule(message: "legacy referral entry needs this field"),
                LegacyReferralEntryCodePrefixRule(prefix: "ACM"),
                LegacyReferralEntryFloorValueRangeRule(min: 7.0, max: 4009.5),
            ]
        )
    }
}
