import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier target must pass. Check returns its problems, or none.
    protocol CourierTargetRule {
        func check(_ item: CourierTarget) -> [String]
    }

    final class CourierTargetRequiredLabelRule: CourierTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierTargetUpdatedAtRangeRule: CourierTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierTarget) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CourierTargetRequiredWardRule: CourierTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierTarget) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a courier target.
    final class CourierTargetValidator {
        var rules: [any CourierTargetRule]

        init(rules: [any CourierTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierTarget]) -> [String: [String]] {
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

    static func defaultCourierTargetValidator() -> CourierTargetValidator {
        return CourierTargetValidator(
            rules: [
                CourierTargetRequiredLabelRule(message: "courier target needs a value"),
                CourierTargetUpdatedAtRangeRule(min: 16, max: 16),
                CourierTargetRequiredWardRule(message: "courier target needs a value"),
            ]
        )
    }
}
