import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan milestone must pass. Check returns its problems, or none.
    protocol AcuityPlanMilestoneRule {
        func check(_ item: AcuityPlanMilestone) -> [String]
    }

    final class AcuityPlanMilestoneCodePrefixRule: AcuityPlanMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AcuityPlanMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AcuityPlanMilestoneLabelLengthRule: AcuityPlanMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanMilestone) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanMilestoneRequiredCodeRule: AcuityPlanMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanMilestoneCodeLengthRule: AcuityPlanMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanMilestoneRateRangeRule: AcuityPlanMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanMilestone) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanMilestoneOwnerIDLengthRule: AcuityPlanMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanMilestone) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan milestone.
    final class AcuityPlanMilestoneValidator {
        var rules: [any AcuityPlanMilestoneRule]

        init(rules: [any AcuityPlanMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanMilestone) -> [String] {
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

        func requireValid(_ item: AcuityPlanMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanMilestone]) -> [String: [String]] {
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

    static func defaultAcuityPlanMilestoneValidator() -> AcuityPlanMilestoneValidator {
        return AcuityPlanMilestoneValidator(
            rules: [
                AcuityPlanMilestoneCodePrefixRule(prefix: "X"),
                AcuityPlanMilestoneLabelLengthRule(maxLength: 255),
                AcuityPlanMilestoneRequiredCodeRule(message: "acuity plan milestone needs an entry"),
                AcuityPlanMilestoneCodeLengthRule(maxLength: 3600),
                AcuityPlanMilestoneRateRangeRule(min: 3.1, max: 1813.1),
                AcuityPlanMilestoneOwnerIDLengthRule(maxLength: 255),
            ]
        )
    }
}
