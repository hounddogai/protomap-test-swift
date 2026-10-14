import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient discharge plan milestone must pass. Check returns its problems, or none.
    protocol LenientDischargePlanMilestoneRule {
        func check(_ item: LenientDischargePlanMilestone) -> [String]
    }

    final class LenientDischargePlanMilestoneRequiredSegmentRule: LenientDischargePlanMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDischargePlanMilestone) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDischargePlanMilestoneBudgetRangeRule: LenientDischargePlanMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientDischargePlanMilestone) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientDischargePlanMilestoneApprovedGuardRule: LenientDischargePlanMilestoneRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientDischargePlanMilestone) -> [String] {
            if item.approved && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class LenientDischargePlanMilestoneNameLengthRule: LenientDischargePlanMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientDischargePlanMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient discharge plan milestone.
    final class LenientDischargePlanMilestoneValidator {
        var rules: [any LenientDischargePlanMilestoneRule]

        init(rules: [any LenientDischargePlanMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientDischargePlanMilestone) -> [String] {
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

        func requireValid(_ item: LenientDischargePlanMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientDischargePlanMilestone]) -> [String: [String]] {
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

    static func defaultLenientDischargePlanMilestoneValidator() -> LenientDischargePlanMilestoneValidator {
        return LenientDischargePlanMilestoneValidator(
            rules: [
                LenientDischargePlanMilestoneRequiredSegmentRule(
                    message: "lenient discharge plan milestone needs an entry"
                ),
                LenientDischargePlanMilestoneBudgetRangeRule(min: 0.8, max: 357.7),
                LenientDischargePlanMilestoneApprovedGuardRule(limit: 255),
                LenientDischargePlanMilestoneNameLengthRule(maxLength: 120),
            ]
        )
    }
}
