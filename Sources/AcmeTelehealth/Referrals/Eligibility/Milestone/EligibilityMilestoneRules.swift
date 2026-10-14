import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility milestone must pass. Check returns its problems, or none.
    protocol EligibilityMilestoneRule {
        func check(_ item: EligibilityMilestone) -> [String]
    }

    final class EligibilityMilestoneDiagnosisCodeLengthRule: EligibilityMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityMilestone) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityMilestoneCodePrefixRule: EligibilityMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class EligibilityMilestoneNameLengthRule: EligibilityMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityMilestoneAcuityRangeRule: EligibilityMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityMilestone) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a eligibility milestone.
    final class EligibilityMilestoneValidator {
        var rules: [any EligibilityMilestoneRule]

        init(rules: [any EligibilityMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityMilestone) -> [String] {
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

        func requireValid(_ item: EligibilityMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityMilestone]) -> [String: [String]] {
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

    static func defaultEligibilityMilestoneValidator() -> EligibilityMilestoneValidator {
        return EligibilityMilestoneValidator(
            rules: [
                EligibilityMilestoneDiagnosisCodeLengthRule(maxLength: 3600),
                EligibilityMilestoneCodePrefixRule(prefix: "ACM"),
                EligibilityMilestoneNameLengthRule(maxLength: 120),
                EligibilityMilestoneAcuityRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
