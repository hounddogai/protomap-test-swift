import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary remittance plan must pass. Check returns its problems, or none.
    protocol PrimaryRemittancePlanRule {
        func check(_ item: PrimaryRemittancePlan) -> [String]
    }

    final class PrimaryRemittancePlanRequiredCodeRule: PrimaryRemittancePlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRemittancePlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRemittancePlanRequiredSpecialtyRule: PrimaryRemittancePlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRemittancePlan) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRemittancePlanDosageMgRangeRule: PrimaryRemittancePlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRemittancePlan) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary remittance plan.
    final class PrimaryRemittancePlanValidator {
        var rules: [any PrimaryRemittancePlanRule]

        init(rules: [any PrimaryRemittancePlanRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryRemittancePlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryRemittancePlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryRemittancePlan]) -> [String: [String]] {
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

    static func defaultPrimaryRemittancePlanValidator() -> PrimaryRemittancePlanValidator {
        return PrimaryRemittancePlanValidator(
            rules: [
                PrimaryRemittancePlanRequiredCodeRule(message: "primary remittance plan needs an entry"),
                PrimaryRemittancePlanRequiredSpecialtyRule(message: "primary remittance plan needs a value"),
                PrimaryRemittancePlanDosageMgRangeRule(min: 8.5, max: 2765.7),
            ]
        )
    }
}
