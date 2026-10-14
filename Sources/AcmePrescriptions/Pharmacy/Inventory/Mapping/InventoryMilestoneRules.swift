import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory milestone must pass. Check returns its problems, or none.
    protocol InventoryMilestoneRule {
        func check(_ item: InventoryMilestone) -> [String]
    }

    final class InventoryMilestoneRequiredSourceRule: InventoryMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryMilestone) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryMilestoneCodePrefixRule: InventoryMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventoryMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InventoryMilestoneDurationMinutesRangeRule: InventoryMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryMilestone) -> [String] {
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

    final class InventoryMilestoneAllowedAllergyRule: InventoryMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventoryMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is unknown"]
            }
            return []
        }
    }

    final class InventoryMilestoneRequiredNameRule: InventoryMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory milestone.
    final class InventoryMilestoneValidator {
        var rules: [any InventoryMilestoneRule]

        init(rules: [any InventoryMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryMilestone]) -> [String: [String]] {
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

    static func defaultInventoryMilestoneValidator() -> InventoryMilestoneValidator {
        return InventoryMilestoneValidator(
            rules: [
                InventoryMilestoneRequiredSourceRule(message: "inventory milestone needs a value"),
                InventoryMilestoneCodePrefixRule(prefix: "OPS"),
                InventoryMilestoneDurationMinutesRangeRule(min: 16, max: 80),
                InventoryMilestoneAllowedAllergyRule(allowed: ["batched"]),
                InventoryMilestoneRequiredNameRule(message: "inventory milestone needs a value"),
            ]
        )
    }
}
