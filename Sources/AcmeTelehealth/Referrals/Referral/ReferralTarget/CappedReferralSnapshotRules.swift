import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped referral snapshot must pass. Check returns its problems, or none.
    protocol CappedReferralSnapshotRule {
        func check(_ item: CappedReferralSnapshot) -> [String]
    }

    final class CappedReferralSnapshotRequiredCodeRule: CappedReferralSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReferralSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedReferralSnapshotRequiredLocaleRule: CappedReferralSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReferralSnapshot) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedReferralSnapshotRequiredFacilityRule: CappedReferralSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReferralSnapshot) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped referral snapshot.
    final class CappedReferralSnapshotValidator {
        var rules: [any CappedReferralSnapshotRule]

        init(rules: [any CappedReferralSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedReferralSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedReferralSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedReferralSnapshot]) -> [String: [String]] {
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

    static func defaultCappedReferralSnapshotValidator() -> CappedReferralSnapshotValidator {
        return CappedReferralSnapshotValidator(
            rules: [
                CappedReferralSnapshotRequiredCodeRule(message: "capped referral snapshot needs an entry"),
                CappedReferralSnapshotRequiredLocaleRule(message: "capped referral snapshot needs an entry"),
                CappedReferralSnapshotRequiredFacilityRule(message: "capped referral snapshot needs an entry"),
            ]
        )
    }
}
