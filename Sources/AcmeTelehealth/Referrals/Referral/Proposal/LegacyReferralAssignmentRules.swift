import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy referral assignment must pass. Check returns its problems, or none.
    protocol LegacyReferralAssignmentRule {
        func check(_ item: LegacyReferralAssignment) -> [String]
    }

    final class LegacyReferralAssignmentVisitMinutesRangeRule: LegacyReferralAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyReferralAssignment) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyReferralAssignmentNameLengthRule: LegacyReferralAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyReferralAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyReferralAssignmentRequiredContactEmailRule: LegacyReferralAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyReferralAssignment) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyReferralAssignmentCodePrefixRule: LegacyReferralAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyReferralAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyReferralAssignmentRequiredCodeRule: LegacyReferralAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyReferralAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy referral assignment.
    final class LegacyReferralAssignmentValidator {
        var rules: [any LegacyReferralAssignmentRule]

        init(rules: [any LegacyReferralAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyReferralAssignment) -> [String] {
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

        func requireValid(_ item: LegacyReferralAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyReferralAssignment]) -> [String: [String]] {
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

    static func defaultLegacyReferralAssignmentValidator() -> LegacyReferralAssignmentValidator {
        return LegacyReferralAssignmentValidator(
            rules: [
                LegacyReferralAssignmentVisitMinutesRangeRule(min: 80, max: 1000),
                LegacyReferralAssignmentNameLengthRule(maxLength: 1000),
                LegacyReferralAssignmentRequiredContactEmailRule(
                    message: "legacy referral assignment needs this field"
                ),
                LegacyReferralAssignmentCodePrefixRule(prefix: "Q"),
                LegacyReferralAssignmentRequiredCodeRule(message: "legacy referral assignment needs an entry"),
            ]
        )
    }
}
