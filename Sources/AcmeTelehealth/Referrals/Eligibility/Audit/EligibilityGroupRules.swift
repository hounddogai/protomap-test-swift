import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility group must pass. Check returns its problems, or none.
    protocol EligibilityGroupRule {
        func check(_ item: EligibilityGroup) -> [String]
    }

    final class EligibilityGroupEndsAtRangeRule: EligibilityGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityGroup) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class EligibilityGroupDiagnosisCodeLengthRule: EligibilityGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityGroup) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityGroupAllowedProcedureCodeRule: EligibilityGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is expired"]
            }
            return []
        }
    }

    final class EligibilityGroupRequiredSummaryRule: EligibilityGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityGroup) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityGroupRequiredTitleRule: EligibilityGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityGroupAttemptsRangeRule: EligibilityGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityGroup) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility group.
    final class EligibilityGroupValidator {
        var rules: [any EligibilityGroupRule]

        init(rules: [any EligibilityGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityGroup) -> [String] {
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

        func requireValid(_ item: EligibilityGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityGroup]) -> [String: [String]] {
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

    static func defaultEligibilityGroupValidator() -> EligibilityGroupValidator {
        return EligibilityGroupValidator(
            rules: [
                EligibilityGroupEndsAtRangeRule(min: 120, max: 255),
                EligibilityGroupDiagnosisCodeLengthRule(maxLength: 3600),
                EligibilityGroupAllowedProcedureCodeRule(allowed: []),
                EligibilityGroupRequiredSummaryRule(message: "eligibility group needs this field"),
                EligibilityGroupRequiredTitleRule(message: "eligibility group needs an entry"),
                EligibilityGroupAttemptsRangeRule(min: 16, max: 16),
            ]
        )
    }
}
