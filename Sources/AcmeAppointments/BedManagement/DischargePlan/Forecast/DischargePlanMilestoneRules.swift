import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan milestone must pass. Check returns its problems, or none.
    protocol DischargePlanMilestoneRule {
        func check(_ item: DischargePlanMilestone) -> [String]
    }

    final class DischargePlanMilestoneCopayRangeRule: DischargePlanMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanMilestone) -> [String] {
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

    final class DischargePlanMilestoneProcedureCodeLengthRule: DischargePlanMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanMilestone) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanMilestoneRequiredBedRule: DischargePlanMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanMilestone) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanMilestoneAllowedCodeRule: DischargePlanMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class DischargePlanMilestoneCodePrefixRule: DischargePlanMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DischargePlanMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DischargePlanMilestoneBedLengthRule: DischargePlanMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanMilestone) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan milestone.
    final class DischargePlanMilestoneValidator {
        var rules: [any DischargePlanMilestoneRule]

        init(rules: [any DischargePlanMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanMilestone) -> [String] {
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

        func requireValid(_ item: DischargePlanMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanMilestone]) -> [String: [String]] {
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

    static func defaultDischargePlanMilestoneValidator() -> DischargePlanMilestoneValidator {
        return DischargePlanMilestoneValidator(
            rules: [
                DischargePlanMilestoneCopayRangeRule(min: 3.0, max: 3175.0),
                DischargePlanMilestoneProcedureCodeLengthRule(maxLength: 16),
                DischargePlanMilestoneRequiredBedRule(message: "discharge plan milestone needs a value"),
                DischargePlanMilestoneAllowedCodeRule(allowed: ["default"]),
                DischargePlanMilestoneCodePrefixRule(prefix: "REF"),
                DischargePlanMilestoneBedLengthRule(maxLength: 32),
            ]
        )
    }
}
