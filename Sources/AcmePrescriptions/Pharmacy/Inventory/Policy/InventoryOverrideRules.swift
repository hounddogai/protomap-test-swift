import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory override must pass. Check returns its problems, or none.
    protocol InventoryOverrideRule {
        func check(_ item: InventoryOverride) -> [String]
    }

    final class InventoryOverrideDosageMgRangeRule: InventoryOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryOverride) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InventoryOverrideCodePrefixRule: InventoryOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventoryOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InventoryOverrideProcedureCodeLengthRule: InventoryOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryOverride) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory override.
    final class InventoryOverrideValidator {
        var rules: [any InventoryOverrideRule]

        init(rules: [any InventoryOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryOverride) -> [String] {
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

        func requireValid(_ item: InventoryOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryOverride]) -> [String: [String]] {
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

    static func defaultInventoryOverrideValidator() -> InventoryOverrideValidator {
        return InventoryOverrideValidator(
            rules: [
                InventoryOverrideDosageMgRangeRule(min: 3.9, max: 2386.9),
                InventoryOverrideCodePrefixRule(prefix: "REF"),
                InventoryOverrideProcedureCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
