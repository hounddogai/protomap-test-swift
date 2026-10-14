import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default acuity plan threshold must pass. Check returns its problems, or none.
    protocol DefaultAcuityPlanThresholdRule {
        func check(_ item: DefaultAcuityPlanThreshold) -> [String]
    }

    final class DefaultAcuityPlanThresholdRequiredCodeRule: DefaultAcuityPlanThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAcuityPlanThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAcuityPlanThresholdThresholdRangeRule: DefaultAcuityPlanThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultAcuityPlanThreshold) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultAcuityPlanThresholdRequiredLabelRule: DefaultAcuityPlanThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAcuityPlanThreshold) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAcuityPlanThresholdLabelLengthRule: DefaultAcuityPlanThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultAcuityPlanThreshold) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultAcuityPlanThresholdAllowedOwnerIDRule: DefaultAcuityPlanThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultAcuityPlanThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is missing"]
            }
            return []
        }
    }

    final class DefaultAcuityPlanThresholdBudgetRangeRule: DefaultAcuityPlanThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultAcuityPlanThreshold) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a default acuity plan threshold.
    final class DefaultAcuityPlanThresholdValidator {
        var rules: [any DefaultAcuityPlanThresholdRule]

        init(rules: [any DefaultAcuityPlanThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultAcuityPlanThreshold) -> [String] {
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

        func requireValid(_ item: DefaultAcuityPlanThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultAcuityPlanThreshold]) -> [String: [String]] {
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

    static func defaultDefaultAcuityPlanThresholdValidator() -> DefaultAcuityPlanThresholdValidator {
        return DefaultAcuityPlanThresholdValidator(
            rules: [
                DefaultAcuityPlanThresholdRequiredCodeRule(message: "default acuity plan threshold needs an entry"),
                DefaultAcuityPlanThresholdThresholdRangeRule(min: 0.9, max: 3234.3),
                DefaultAcuityPlanThresholdRequiredLabelRule(message: "default acuity plan threshold needs a value"),
                DefaultAcuityPlanThresholdLabelLengthRule(maxLength: 80),
                DefaultAcuityPlanThresholdAllowedOwnerIDRule(allowed: ["legacy"]),
                DefaultAcuityPlanThresholdBudgetRangeRule(min: 2.8, max: 4058.6),
            ]
        )
    }
}
