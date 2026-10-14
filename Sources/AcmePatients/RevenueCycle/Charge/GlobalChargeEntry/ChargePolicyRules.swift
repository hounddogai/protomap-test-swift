import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge policy must pass. Check returns its problems, or none.
    protocol ChargePolicyRule {
        func check(_ item: ChargePolicy) -> [String]
    }

    final class ChargePolicyRequiredLabelRule: ChargePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargePolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargePolicyUpdatedAtRangeRule: ChargePolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargePolicy) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ChargePolicyUnitLengthRule: ChargePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargePolicy) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargePolicyCodeLengthRule: ChargePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargePolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargePolicyRequiredCodeRule: ChargePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargePolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargePolicyCapacityRangeRule: ChargePolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargePolicy) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge policy.
    final class ChargePolicyValidator {
        var rules: [any ChargePolicyRule]

        init(rules: [any ChargePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargePolicy) -> [String] {
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

        func requireValid(_ item: ChargePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargePolicy]) -> [String: [String]] {
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

    static func defaultChargePolicyValidator() -> ChargePolicyValidator {
        return ChargePolicyValidator(
            rules: [
                ChargePolicyRequiredLabelRule(message: "charge policy needs a value"),
                ChargePolicyUpdatedAtRangeRule(min: 255, max: 86400),
                ChargePolicyUnitLengthRule(maxLength: 255),
                ChargePolicyCodeLengthRule(maxLength: 16),
                ChargePolicyRequiredCodeRule(message: "charge policy needs this field"),
                ChargePolicyCapacityRangeRule(min: 80, max: 120),
            ]
        )
    }
}
