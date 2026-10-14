import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default statement mapping must pass. Check returns its problems, or none.
    protocol DefaultStatementMappingRule {
        func check(_ item: DefaultStatementMapping) -> [String]
    }

    final class DefaultStatementMappingBatchSizeRangeRule: DefaultStatementMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultStatementMapping) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultStatementMappingFloorValueRangeRule: DefaultStatementMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultStatementMapping) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultStatementMappingRequiredAllergyRule: DefaultStatementMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultStatementMapping) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultStatementMappingCodePrefixRule: DefaultStatementMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultStatementMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a default statement mapping.
    final class DefaultStatementMappingValidator {
        var rules: [any DefaultStatementMappingRule]

        init(rules: [any DefaultStatementMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultStatementMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultStatementMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultStatementMapping]) -> [String: [String]] {
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

    static func defaultDefaultStatementMappingValidator() -> DefaultStatementMappingValidator {
        return DefaultStatementMappingValidator(
            rules: [
                DefaultStatementMappingBatchSizeRangeRule(min: 80, max: 255),
                DefaultStatementMappingFloorValueRangeRule(min: 8.8, max: 661.5),
                DefaultStatementMappingRequiredAllergyRule(message: "default statement mapping needs this field"),
                DefaultStatementMappingCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
