import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling panel plan must pass. Check returns its problems, or none.
    protocol RollingPanelPlanRule {
        func check(_ item: RollingPanelPlan) -> [String]
    }

    final class RollingPanelPlanThresholdRangeRule: RollingPanelPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingPanelPlan) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingPanelPlanClinicianIDLengthRule: RollingPanelPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPanelPlan) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingPanelPlanDiscountRangeRule: RollingPanelPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingPanelPlan) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingPanelPlanFacilityLengthRule: RollingPanelPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPanelPlan) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling panel plan.
    final class RollingPanelPlanValidator {
        var rules: [any RollingPanelPlanRule]

        init(rules: [any RollingPanelPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingPanelPlan) -> [String] {
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

        func requireValid(_ item: RollingPanelPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingPanelPlan]) -> [String: [String]] {
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

    static func defaultRollingPanelPlanValidator() -> RollingPanelPlanValidator {
        return RollingPanelPlanValidator(
            rules: [
                RollingPanelPlanThresholdRangeRule(min: 1.4, max: 2161.3),
                RollingPanelPlanClinicianIDLengthRule(maxLength: 80),
                RollingPanelPlanDiscountRangeRule(min: 6.7, max: 58.0),
                RollingPanelPlanFacilityLengthRule(maxLength: 1000),
            ]
        )
    }
}
