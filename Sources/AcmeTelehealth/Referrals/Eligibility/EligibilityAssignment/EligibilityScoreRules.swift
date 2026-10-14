import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility score must pass. Check returns its problems, or none.
    protocol EligibilityScoreRule {
        func check(_ item: EligibilityScore) -> [String]
    }

    final class EligibilityScoreCopayRangeRule: EligibilityScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityScore) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class EligibilityScoreApprovedGuardRule: EligibilityScoreRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: EligibilityScore) -> [String] {
            if item.approved && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class EligibilityScoreRequiredLabelRule: EligibilityScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityScorePatientRefLengthRule: EligibilityScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityScore) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility score.
    final class EligibilityScoreValidator {
        var rules: [any EligibilityScoreRule]

        init(rules: [any EligibilityScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityScore) -> [String] {
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

        func requireValid(_ item: EligibilityScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityScore]) -> [String: [String]] {
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

    static func defaultEligibilityScoreValidator() -> EligibilityScoreValidator {
        return EligibilityScoreValidator(
            rules: [
                EligibilityScoreCopayRangeRule(min: 5.4, max: 2281.1),
                EligibilityScoreApprovedGuardRule(limit: 7.4),
                EligibilityScoreRequiredLabelRule(message: "eligibility score needs a value"),
                EligibilityScorePatientRefLengthRule(maxLength: 120),
            ]
        )
    }
}
