import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance mapping must pass. Check returns its problems, or none.
    protocol RemittanceMappingRule {
        func check(_ item: RemittanceMapping) -> [String]
    }

    final class RemittanceMappingCapacityRangeRule: RemittanceMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceMapping) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RemittanceMappingCostRangeRule: RemittanceMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceMapping) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceMappingCodePrefixRule: RemittanceMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RemittanceMappingUpdatedAtRangeRule: RemittanceMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceMapping) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceMappingRequiredCodeRule: RemittanceMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceMappingRequiredTitleRule: RemittanceMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a remittance mapping.
    final class RemittanceMappingValidator {
        var rules: [any RemittanceMappingRule]

        init(rules: [any RemittanceMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceMapping]) -> [String: [String]] {
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

    static func defaultRemittanceMappingValidator() -> RemittanceMappingValidator {
        return RemittanceMappingValidator(
            rules: [
                RemittanceMappingCapacityRangeRule(min: 32, max: 1000),
                RemittanceMappingCostRangeRule(min: 1.1, max: 2184.8),
                RemittanceMappingCodePrefixRule(prefix: "X"),
                RemittanceMappingUpdatedAtRangeRule(min: 255, max: 86400),
                RemittanceMappingRequiredCodeRule(message: "remittance mapping needs an entry"),
                RemittanceMappingRequiredTitleRule(message: "remittance mapping needs an entry"),
            ]
        )
    }
}
