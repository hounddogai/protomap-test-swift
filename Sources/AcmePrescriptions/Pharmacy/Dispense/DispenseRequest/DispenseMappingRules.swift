import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense mapping must pass. Check returns its problems, or none.
    protocol DispenseMappingRule {
        func check(_ item: DispenseMapping) -> [String]
    }

    final class DispenseMappingThresholdRangeRule: DispenseMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseMapping) -> [String] {
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

    final class DispenseMappingRequiredCodeRule: DispenseMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseMappingCodePrefixRule: DispenseMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DispenseMappingAllowedNameRule: DispenseMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class DispenseMappingNameLengthRule: DispenseMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseMappingRequiredProcedureCodeRule: DispenseMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseMapping) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a dispense mapping.
    final class DispenseMappingValidator {
        var rules: [any DispenseMappingRule]

        init(rules: [any DispenseMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseMapping]) -> [String: [String]] {
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

    static func defaultDispenseMappingValidator() -> DispenseMappingValidator {
        return DispenseMappingValidator(
            rules: [
                DispenseMappingThresholdRangeRule(min: 8.0, max: 3690.9),
                DispenseMappingRequiredCodeRule(message: "dispense mapping needs this field"),
                DispenseMappingCodePrefixRule(prefix: "Q"),
                DispenseMappingAllowedNameRule(allowed: ["fallback", "adaptive"]),
                DispenseMappingNameLengthRule(maxLength: 64),
                DispenseMappingRequiredProcedureCodeRule(message: "dispense mapping needs a value"),
            ]
        )
    }
}
