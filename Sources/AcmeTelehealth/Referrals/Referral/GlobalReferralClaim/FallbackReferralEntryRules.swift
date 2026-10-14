import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback referral entry must pass. Check returns its problems, or none.
    protocol FallbackReferralEntryRule {
        func check(_ item: FallbackReferralEntry) -> [String]
    }

    final class FallbackReferralEntryRequiredPhoneRule: FallbackReferralEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackReferralEntry) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackReferralEntryWardLengthRule: FallbackReferralEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackReferralEntry) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackReferralEntryPhoneLengthRule: FallbackReferralEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackReferralEntry) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackReferralEntrySequenceRangeRule: FallbackReferralEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackReferralEntry) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackReferralEntryFloorValueRangeRule: FallbackReferralEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackReferralEntry) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a fallback referral entry.
    final class FallbackReferralEntryValidator {
        var rules: [any FallbackReferralEntryRule]

        init(rules: [any FallbackReferralEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackReferralEntry) -> [String] {
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

        func requireValid(_ item: FallbackReferralEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackReferralEntry]) -> [String: [String]] {
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

    static func defaultFallbackReferralEntryValidator() -> FallbackReferralEntryValidator {
        return FallbackReferralEntryValidator(
            rules: [
                FallbackReferralEntryRequiredPhoneRule(message: "fallback referral entry needs an entry"),
                FallbackReferralEntryWardLengthRule(maxLength: 16),
                FallbackReferralEntryPhoneLengthRule(maxLength: 64),
                FallbackReferralEntrySequenceRangeRule(min: 64, max: 3600),
                FallbackReferralEntryFloorValueRangeRule(min: 3.2, max: 2841.5),
            ]
        )
    }
}
