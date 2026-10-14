import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled consent form claim must pass. Check returns its problems, or none.
    protocol ScheduledConsentFormClaimRule {
        func check(_ item: ScheduledConsentFormClaim) -> [String]
    }

    final class ScheduledConsentFormClaimStartsAtRangeRule: ScheduledConsentFormClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledConsentFormClaim) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledConsentFormClaimReviewerLengthRule: ScheduledConsentFormClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledConsentFormClaim) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledConsentFormClaimTitleLengthRule: ScheduledConsentFormClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledConsentFormClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledConsentFormClaimMinimumRangeRule: ScheduledConsentFormClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledConsentFormClaim) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledConsentFormClaimQuantityRangeRule: ScheduledConsentFormClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledConsentFormClaim) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledConsentFormClaimDiagnosisCodeLengthRule: ScheduledConsentFormClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledConsentFormClaim) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled consent form claim.
    final class ScheduledConsentFormClaimValidator {
        var rules: [any ScheduledConsentFormClaimRule]

        init(rules: [any ScheduledConsentFormClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledConsentFormClaim) -> [String] {
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

        func requireValid(_ item: ScheduledConsentFormClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledConsentFormClaim]) -> [String: [String]] {
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

    static func defaultScheduledConsentFormClaimValidator() -> ScheduledConsentFormClaimValidator {
        return ScheduledConsentFormClaimValidator(
            rules: [
                ScheduledConsentFormClaimStartsAtRangeRule(min: 16, max: 3600),
                ScheduledConsentFormClaimReviewerLengthRule(maxLength: 80),
                ScheduledConsentFormClaimTitleLengthRule(maxLength: 3600),
                ScheduledConsentFormClaimMinimumRangeRule(min: 1.2, max: 397.1),
                ScheduledConsentFormClaimQuantityRangeRule(min: 120, max: 255),
                ScheduledConsentFormClaimDiagnosisCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
