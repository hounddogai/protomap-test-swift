import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global credential milestone must pass. Check returns its problems, or none.
    protocol GlobalCredentialMilestoneRule {
        func check(_ item: GlobalCredentialMilestone) -> [String]
    }

    final class GlobalCredentialMilestoneAllergyLengthRule: GlobalCredentialMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCredentialMilestone) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCredentialMilestoneRetriesRangeRule: GlobalCredentialMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCredentialMilestone) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalCredentialMilestoneCodeLengthRule: GlobalCredentialMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCredentialMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global credential milestone.
    final class GlobalCredentialMilestoneValidator {
        var rules: [any GlobalCredentialMilestoneRule]

        init(rules: [any GlobalCredentialMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCredentialMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalCredentialMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCredentialMilestone]) -> [String: [String]] {
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

    static func defaultGlobalCredentialMilestoneValidator() -> GlobalCredentialMilestoneValidator {
        return GlobalCredentialMilestoneValidator(
            rules: [
                GlobalCredentialMilestoneAllergyLengthRule(maxLength: 16),
                GlobalCredentialMilestoneRetriesRangeRule(min: 120, max: 120),
                GlobalCredentialMilestoneCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
