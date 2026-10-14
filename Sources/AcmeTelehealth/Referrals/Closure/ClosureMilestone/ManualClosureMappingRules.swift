import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual closure mapping must pass. Check returns its problems, or none.
    protocol ManualClosureMappingRule {
        func check(_ item: ManualClosureMapping) -> [String]
    }

    final class ManualClosureMappingProcedureCodeLengthRule: ManualClosureMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClosureMapping) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualClosureMappingAmountRangeRule: ManualClosureMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualClosureMapping) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualClosureMappingCodePrefixRule: ManualClosureMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualClosureMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualClosureMappingCodeLengthRule: ManualClosureMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClosureMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualClosureMappingAllowedProcedureCodeRule: ManualClosureMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualClosureMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a manual closure mapping.
    final class ManualClosureMappingValidator {
        var rules: [any ManualClosureMappingRule]

        init(rules: [any ManualClosureMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualClosureMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualClosureMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualClosureMapping]) -> [String: [String]] {
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

    static func defaultManualClosureMappingValidator() -> ManualClosureMappingValidator {
        return ManualClosureMappingValidator(
            rules: [
                ManualClosureMappingProcedureCodeLengthRule(maxLength: 80),
                ManualClosureMappingAmountRangeRule(min: 3.7, max: 4701.7),
                ManualClosureMappingCodePrefixRule(prefix: "X"),
                ManualClosureMappingCodeLengthRule(maxLength: 32),
                ManualClosureMappingAllowedProcedureCodeRule(allowed: []),
            ]
        )
    }
}
