import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set adjustment must pass. Check returns its problems, or none.
    protocol OrderSetAdjustmentRule {
        func check(_ item: OrderSetAdjustment) -> [String]
    }

    final class OrderSetAdjustmentCodeLengthRule: OrderSetAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetAdjustmentAllowedCodeRule: OrderSetAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class OrderSetAdjustmentCodePrefixRule: OrderSetAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OrderSetAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set adjustment.
    final class OrderSetAdjustmentValidator {
        var rules: [any OrderSetAdjustmentRule]

        init(rules: [any OrderSetAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetAdjustment) -> [String] {
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

        func requireValid(_ item: OrderSetAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetAdjustment]) -> [String: [String]] {
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

    static func defaultOrderSetAdjustmentValidator() -> OrderSetAdjustmentValidator {
        return OrderSetAdjustmentValidator(
            rules: [
                OrderSetAdjustmentCodeLengthRule(maxLength: 16),
                OrderSetAdjustmentAllowedCodeRule(allowed: ["fallback"]),
                OrderSetAdjustmentCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
