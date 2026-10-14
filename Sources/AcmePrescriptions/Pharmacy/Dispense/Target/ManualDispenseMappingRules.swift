import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual dispense mapping must pass. Check returns its problems, or none.
    protocol ManualDispenseMappingRule {
        func check(_ item: ManualDispenseMapping) -> [String]
    }

    final class ManualDispenseMappingAllowedWardRule: ManualDispenseMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualDispenseMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is unknown"]
            }
            return []
        }
    }

    final class ManualDispenseMappingRequiredWardRule: ManualDispenseMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDispenseMapping) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDispenseMappingAttemptsRangeRule: ManualDispenseMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualDispenseMapping) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualDispenseMappingCodePrefixRule: ManualDispenseMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualDispenseMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualDispenseMappingRequiredLabelRule: ManualDispenseMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDispenseMapping) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual dispense mapping.
    final class ManualDispenseMappingValidator {
        var rules: [any ManualDispenseMappingRule]

        init(rules: [any ManualDispenseMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualDispenseMapping) -> [String] {
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

        func requireValid(_ item: ManualDispenseMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualDispenseMapping]) -> [String: [String]] {
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

    static func defaultManualDispenseMappingValidator() -> ManualDispenseMappingValidator {
        return ManualDispenseMappingValidator(
            rules: [
                ManualDispenseMappingAllowedWardRule(allowed: ["scheduled", "scheduled"]),
                ManualDispenseMappingRequiredWardRule(message: "manual dispense mapping needs an entry"),
                ManualDispenseMappingAttemptsRangeRule(min: 16, max: 120),
                ManualDispenseMappingCodePrefixRule(prefix: "ACM"),
                ManualDispenseMappingRequiredLabelRule(message: "manual dispense mapping needs this field"),
            ]
        )
    }
}
