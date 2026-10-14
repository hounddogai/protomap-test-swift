import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling claim plan must pass. Check returns its problems, or none.
    protocol RollingClaimPlanRule {
        func check(_ item: RollingClaimPlan) -> [String]
    }

    final class RollingClaimPlanRequiredPatientRefRule: RollingClaimPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingClaimPlan) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingClaimPlanSequenceRangeRule: RollingClaimPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingClaimPlan) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingClaimPlanRequiredCodeRule: RollingClaimPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingClaimPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingClaimPlanCodeLengthRule: RollingClaimPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingClaimPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling claim plan.
    final class RollingClaimPlanValidator {
        var rules: [any RollingClaimPlanRule]

        init(rules: [any RollingClaimPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingClaimPlan) -> [String] {
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

        func requireValid(_ item: RollingClaimPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingClaimPlan]) -> [String: [String]] {
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

    static func defaultRollingClaimPlanValidator() -> RollingClaimPlanValidator {
        return RollingClaimPlanValidator(
            rules: [
                RollingClaimPlanRequiredPatientRefRule(message: "rolling claim plan needs a value"),
                RollingClaimPlanSequenceRangeRule(min: 64, max: 255),
                RollingClaimPlanRequiredCodeRule(message: "rolling claim plan needs an entry"),
                RollingClaimPlanCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
