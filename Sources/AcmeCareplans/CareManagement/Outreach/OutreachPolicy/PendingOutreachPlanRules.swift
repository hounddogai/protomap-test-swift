import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending outreach plan must pass. Check returns its problems, or none.
    protocol PendingOutreachPlanRule {
        func check(_ item: PendingOutreachPlan) -> [String]
    }

    final class PendingOutreachPlanRequiredPhoneRule: PendingOutreachPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingOutreachPlan) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingOutreachPlanVisibleGuardRule: PendingOutreachPlanRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PendingOutreachPlan) -> [String] {
            if item.visible && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class PendingOutreachPlanRatioRangeRule: PendingOutreachPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOutreachPlan) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingOutreachPlanTitleLengthRule: PendingOutreachPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingOutreachPlan) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingOutreachPlanCeilingRangeRule: PendingOutreachPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOutreachPlan) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingOutreachPlanCodePrefixRule: PendingOutreachPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingOutreachPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending outreach plan.
    final class PendingOutreachPlanValidator {
        var rules: [any PendingOutreachPlanRule]

        init(rules: [any PendingOutreachPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingOutreachPlan) -> [String] {
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

        func requireValid(_ item: PendingOutreachPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingOutreachPlan]) -> [String: [String]] {
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

    static func defaultPendingOutreachPlanValidator() -> PendingOutreachPlanValidator {
        return PendingOutreachPlanValidator(
            rules: [
                PendingOutreachPlanRequiredPhoneRule(message: "pending outreach plan needs this field"),
                PendingOutreachPlanVisibleGuardRule(limit: 5.1),
                PendingOutreachPlanRatioRangeRule(min: 9.2, max: 3688.9),
                PendingOutreachPlanTitleLengthRule(maxLength: 16),
                PendingOutreachPlanCeilingRangeRule(min: 0.8, max: 709.0),
                PendingOutreachPlanCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
