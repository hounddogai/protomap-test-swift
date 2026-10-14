import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered acuity plan milestone must pass. Check returns its problems, or none.
    protocol TieredAcuityPlanMilestoneRule {
        func check(_ item: TieredAcuityPlanMilestone) -> [String]
    }

    final class TieredAcuityPlanMilestoneRequiredCodeRule: TieredAcuityPlanMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAcuityPlanMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAcuityPlanMilestoneCodePrefixRule: TieredAcuityPlanMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredAcuityPlanMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredAcuityPlanMilestoneRequiredProcedureCodeRule: TieredAcuityPlanMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAcuityPlanMilestone) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAcuityPlanMilestoneCreatedAtRangeRule: TieredAcuityPlanMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredAcuityPlanMilestone) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredAcuityPlanMilestoneRequiredNameRule: TieredAcuityPlanMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAcuityPlanMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAcuityPlanMilestoneRequiredWardRule: TieredAcuityPlanMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAcuityPlanMilestone) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered acuity plan milestone.
    final class TieredAcuityPlanMilestoneValidator {
        var rules: [any TieredAcuityPlanMilestoneRule]

        init(rules: [any TieredAcuityPlanMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredAcuityPlanMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredAcuityPlanMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredAcuityPlanMilestone]) -> [String: [String]] {
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

    static func defaultTieredAcuityPlanMilestoneValidator() -> TieredAcuityPlanMilestoneValidator {
        return TieredAcuityPlanMilestoneValidator(
            rules: [
                TieredAcuityPlanMilestoneRequiredCodeRule(message: "tiered acuity plan milestone needs an entry"),
                TieredAcuityPlanMilestoneCodePrefixRule(prefix: "Q"),
                TieredAcuityPlanMilestoneRequiredProcedureCodeRule(
                    message: "tiered acuity plan milestone needs a value"
                ),
                TieredAcuityPlanMilestoneCreatedAtRangeRule(min: 16, max: 32),
                TieredAcuityPlanMilestoneRequiredNameRule(message: "tiered acuity plan milestone needs a value"),
                TieredAcuityPlanMilestoneRequiredWardRule(message: "tiered acuity plan milestone needs an entry"),
            ]
        )
    }
}
