import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default acuity plan milestone must pass. Check returns its problems, or none.
    protocol DefaultAcuityPlanMilestoneRule {
        func check(_ item: DefaultAcuityPlanMilestone) -> [String]
    }

    final class DefaultAcuityPlanMilestoneRequiredTitleRule: DefaultAcuityPlanMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAcuityPlanMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAcuityPlanMilestoneRequiredCodeRule: DefaultAcuityPlanMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAcuityPlanMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAcuityPlanMilestoneClinicianIDLengthRule: DefaultAcuityPlanMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultAcuityPlanMilestone) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultAcuityPlanMilestoneTitleLengthRule: DefaultAcuityPlanMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultAcuityPlanMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultAcuityPlanMilestoneLocaleLengthRule: DefaultAcuityPlanMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultAcuityPlanMilestone) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default acuity plan milestone.
    final class DefaultAcuityPlanMilestoneValidator {
        var rules: [any DefaultAcuityPlanMilestoneRule]

        init(rules: [any DefaultAcuityPlanMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultAcuityPlanMilestone) -> [String] {
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

        func requireValid(_ item: DefaultAcuityPlanMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultAcuityPlanMilestone]) -> [String: [String]] {
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

    static func defaultDefaultAcuityPlanMilestoneValidator() -> DefaultAcuityPlanMilestoneValidator {
        return DefaultAcuityPlanMilestoneValidator(
            rules: [
                DefaultAcuityPlanMilestoneRequiredTitleRule(message: "default acuity plan milestone needs this field"),
                DefaultAcuityPlanMilestoneRequiredCodeRule(message: "default acuity plan milestone needs this field"),
                DefaultAcuityPlanMilestoneClinicianIDLengthRule(maxLength: 1000),
                DefaultAcuityPlanMilestoneTitleLengthRule(maxLength: 255),
                DefaultAcuityPlanMilestoneLocaleLengthRule(maxLength: 255),
            ]
        )
    }
}
