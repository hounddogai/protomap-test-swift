import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier plan must pass. Check returns its problems, or none.
    protocol CourierPlanRule {
        func check(_ item: CourierPlan) -> [String]
    }

    final class CourierPlanLabelLengthRule: CourierPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierPlan) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierPlanVersionRangeRule: CourierPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierPlan) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CourierPlanCodePrefixRule: CourierPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CourierPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CourierPlanAllowedCodeRule: CourierPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class CourierPlanRequiredNameRule: CourierPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierPlan) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierPlanPatientRefLengthRule: CourierPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierPlan) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a courier plan.
    final class CourierPlanValidator {
        var rules: [any CourierPlanRule]

        init(rules: [any CourierPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierPlan]) -> [String: [String]] {
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

    static func defaultCourierPlanValidator() -> CourierPlanValidator {
        return CourierPlanValidator(
            rules: [
                CourierPlanLabelLengthRule(maxLength: 80),
                CourierPlanVersionRangeRule(min: 64, max: 255),
                CourierPlanCodePrefixRule(prefix: "X"),
                CourierPlanAllowedCodeRule(allowed: ["seasonal", "legacy", "seasonal"]),
                CourierPlanRequiredNameRule(message: "courier plan needs this field"),
                CourierPlanPatientRefLengthRule(maxLength: 1000),
            ]
        )
    }
}
