import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral snapshot must pass. Check returns its problems, or none.
    protocol ReferralSnapshotRule {
        func check(_ item: ReferralSnapshot) -> [String]
    }

    final class ReferralSnapshotRequiredTitleRule: ReferralSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralSnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralSnapshotRegionLengthRule: ReferralSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralSnapshot) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralSnapshotCodeLengthRule: ReferralSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralSnapshotTitleLengthRule: ReferralSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralSnapshot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralSnapshotSequenceRangeRule: ReferralSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralSnapshot) -> [String] {
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

    /// Runs every rule of a referral snapshot.
    final class ReferralSnapshotValidator {
        var rules: [any ReferralSnapshotRule]

        init(rules: [any ReferralSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralSnapshot]) -> [String: [String]] {
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

    static func defaultReferralSnapshotValidator() -> ReferralSnapshotValidator {
        return ReferralSnapshotValidator(
            rules: [
                ReferralSnapshotRequiredTitleRule(message: "referral snapshot needs this field"),
                ReferralSnapshotRegionLengthRule(maxLength: 120),
                ReferralSnapshotCodeLengthRule(maxLength: 80),
                ReferralSnapshotTitleLengthRule(maxLength: 16),
                ReferralSnapshotSequenceRangeRule(min: 120, max: 255),
            ]
        )
    }
}
