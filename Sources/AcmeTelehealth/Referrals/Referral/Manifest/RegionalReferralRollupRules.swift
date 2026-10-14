import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional referral rollup must pass. Check returns its problems, or none.
    protocol RegionalReferralRollupRule {
        func check(_ item: RegionalReferralRollup) -> [String]
    }

    final class RegionalReferralRollupPatientRefLengthRule: RegionalReferralRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalReferralRollup) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalReferralRollupRequiredTitleRule: RegionalReferralRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalReferralRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalReferralRollupRequiredNotesRule: RegionalReferralRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalReferralRollup) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalReferralRollupTitleLengthRule: RegionalReferralRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalReferralRollup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional referral rollup.
    final class RegionalReferralRollupValidator {
        var rules: [any RegionalReferralRollupRule]

        init(rules: [any RegionalReferralRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalReferralRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalReferralRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalReferralRollup]) -> [String: [String]] {
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

    static func defaultRegionalReferralRollupValidator() -> RegionalReferralRollupValidator {
        return RegionalReferralRollupValidator(
            rules: [
                RegionalReferralRollupPatientRefLengthRule(maxLength: 80),
                RegionalReferralRollupRequiredTitleRule(message: "regional referral rollup needs a value"),
                RegionalReferralRollupRequiredNotesRule(message: "regional referral rollup needs a value"),
                RegionalReferralRollupTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
