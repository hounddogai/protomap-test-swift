import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a batched acuity plan milestone must pass. Check returns its problems, or none.
    protocol BatchedAcuityPlanMilestoneRule {
        func check(_ item: BatchedAcuityPlanMilestone) -> [String]
    }

    final class BatchedAcuityPlanMilestoneMaximumRangeRule: BatchedAcuityPlanMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedAcuityPlanMilestone) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedAcuityPlanMilestoneRequiredCodeRule: BatchedAcuityPlanMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAcuityPlanMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAcuityPlanMilestoneRegionLengthRule: BatchedAcuityPlanMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAcuityPlanMilestone) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedAcuityPlanMilestoneCodeLengthRule: BatchedAcuityPlanMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAcuityPlanMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedAcuityPlanMilestoneRequiredLabelRule: BatchedAcuityPlanMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAcuityPlanMilestone) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAcuityPlanMilestoneVisitMinutesRangeRule: BatchedAcuityPlanMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedAcuityPlanMilestone) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched acuity plan milestone.
    final class BatchedAcuityPlanMilestoneValidator {
        var rules: [any BatchedAcuityPlanMilestoneRule]

        init(rules: [any BatchedAcuityPlanMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedAcuityPlanMilestone) -> [String] {
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

        func requireValid(_ item: BatchedAcuityPlanMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedAcuityPlanMilestone]) -> [String: [String]] {
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

    static func defaultBatchedAcuityPlanMilestoneValidator() -> BatchedAcuityPlanMilestoneValidator {
        return BatchedAcuityPlanMilestoneValidator(
            rules: [
                BatchedAcuityPlanMilestoneMaximumRangeRule(min: 7.9, max: 859.4),
                BatchedAcuityPlanMilestoneRequiredCodeRule(message: "batched acuity plan milestone needs an entry"),
                BatchedAcuityPlanMilestoneRegionLengthRule(maxLength: 80),
                BatchedAcuityPlanMilestoneCodeLengthRule(maxLength: 3600),
                BatchedAcuityPlanMilestoneRequiredLabelRule(message: "batched acuity plan milestone needs a value"),
                BatchedAcuityPlanMilestoneVisitMinutesRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
