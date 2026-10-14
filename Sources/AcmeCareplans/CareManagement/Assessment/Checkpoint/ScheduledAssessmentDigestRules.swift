import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled assessment digest must pass. Check returns its problems, or none.
    protocol ScheduledAssessmentDigestRule {
        func check(_ item: ScheduledAssessmentDigest) -> [String]
    }

    final class ScheduledAssessmentDigestClinicianIDLengthRule: ScheduledAssessmentDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAssessmentDigest) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledAssessmentDigestBudgetRangeRule: ScheduledAssessmentDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledAssessmentDigest) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledAssessmentDigestLimitRangeRule: ScheduledAssessmentDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledAssessmentDigest) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledAssessmentDigestAllergyLengthRule: ScheduledAssessmentDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAssessmentDigest) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled assessment digest.
    final class ScheduledAssessmentDigestValidator {
        var rules: [any ScheduledAssessmentDigestRule]

        init(rules: [any ScheduledAssessmentDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAssessmentDigest) -> [String] {
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

        func requireValid(_ item: ScheduledAssessmentDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAssessmentDigest]) -> [String: [String]] {
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

    static func defaultScheduledAssessmentDigestValidator() -> ScheduledAssessmentDigestValidator {
        return ScheduledAssessmentDigestValidator(
            rules: [
                ScheduledAssessmentDigestClinicianIDLengthRule(maxLength: 32),
                ScheduledAssessmentDigestBudgetRangeRule(min: 1.7, max: 192.2),
                ScheduledAssessmentDigestLimitRangeRule(min: 16, max: 64),
                ScheduledAssessmentDigestAllergyLengthRule(maxLength: 80),
            ]
        )
    }
}
