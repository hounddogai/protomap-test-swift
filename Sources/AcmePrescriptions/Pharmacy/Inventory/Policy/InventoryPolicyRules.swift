import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory policy must pass. Check returns its problems, or none.
    protocol InventoryPolicyRule {
        func check(_ item: InventoryPolicy) -> [String]
    }

    final class InventoryPolicyRequiredTimezoneRule: InventoryPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryPolicy) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryPolicyRequiredNameRule: InventoryPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryPolicyDurationMinutesRangeRule: InventoryPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryPolicy) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InventoryPolicyRequiredCodeRule: InventoryPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory policy.
    final class InventoryPolicyValidator {
        var rules: [any InventoryPolicyRule]

        init(rules: [any InventoryPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryPolicy) -> [String] {
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

        func requireValid(_ item: InventoryPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryPolicy]) -> [String: [String]] {
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

    static func defaultInventoryPolicyValidator() -> InventoryPolicyValidator {
        return InventoryPolicyValidator(
            rules: [
                InventoryPolicyRequiredTimezoneRule(message: "inventory policy needs a value"),
                InventoryPolicyRequiredNameRule(message: "inventory policy needs a value"),
                InventoryPolicyDurationMinutesRangeRule(min: 255, max: 1000),
                InventoryPolicyRequiredCodeRule(message: "inventory policy needs this field"),
            ]
        )
    }
}
