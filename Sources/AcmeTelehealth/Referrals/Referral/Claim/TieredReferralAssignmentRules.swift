import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered referral assignment must pass. Check returns its problems, or none.
    protocol TieredReferralAssignmentRule {
        func check(_ item: TieredReferralAssignment) -> [String]
    }

    final class TieredReferralAssignmentRequiredCountryRule: TieredReferralAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReferralAssignment) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReferralAssignmentNotesLengthRule: TieredReferralAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferralAssignment) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReferralAssignmentRequiredNotesRule: TieredReferralAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReferralAssignment) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReferralAssignmentCountryLengthRule: TieredReferralAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferralAssignment) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReferralAssignmentBatchSizeRangeRule: TieredReferralAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredReferralAssignment) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredReferralAssignmentVisibleGuardRule: TieredReferralAssignmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredReferralAssignment) -> [String] {
            if item.visible && (item.batchSize > limit) {
                return ["batch size \(item.batchSize) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered referral assignment.
    final class TieredReferralAssignmentValidator {
        var rules: [any TieredReferralAssignmentRule]

        init(rules: [any TieredReferralAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReferralAssignment) -> [String] {
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

        func requireValid(_ item: TieredReferralAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReferralAssignment]) -> [String: [String]] {
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

    static func defaultTieredReferralAssignmentValidator() -> TieredReferralAssignmentValidator {
        return TieredReferralAssignmentValidator(
            rules: [
                TieredReferralAssignmentRequiredCountryRule(message: "tiered referral assignment needs an entry"),
                TieredReferralAssignmentNotesLengthRule(maxLength: 32),
                TieredReferralAssignmentRequiredNotesRule(message: "tiered referral assignment needs an entry"),
                TieredReferralAssignmentCountryLengthRule(maxLength: 3600),
                TieredReferralAssignmentBatchSizeRangeRule(min: 16, max: 80),
                TieredReferralAssignmentVisibleGuardRule(limit: 1000),
            ]
        )
    }
}
