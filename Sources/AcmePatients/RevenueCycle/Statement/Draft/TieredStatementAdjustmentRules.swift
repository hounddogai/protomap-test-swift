import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered statement adjustment must pass. Check returns its problems, or none.
    protocol TieredStatementAdjustmentRule {
        func check(_ item: TieredStatementAdjustment) -> [String]
    }

    final class TieredStatementAdjustmentCodeLengthRule: TieredStatementAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredStatementAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredStatementAdjustmentLabelLengthRule: TieredStatementAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredStatementAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredStatementAdjustmentRequiredCodeRule: TieredStatementAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredStatementAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredStatementAdjustmentCodePrefixRule: TieredStatementAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredStatementAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered statement adjustment.
    final class TieredStatementAdjustmentValidator {
        var rules: [any TieredStatementAdjustmentRule]

        init(rules: [any TieredStatementAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredStatementAdjustment) -> [String] {
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

        func requireValid(_ item: TieredStatementAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredStatementAdjustment]) -> [String: [String]] {
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

    static func defaultTieredStatementAdjustmentValidator() -> TieredStatementAdjustmentValidator {
        return TieredStatementAdjustmentValidator(
            rules: [
                TieredStatementAdjustmentCodeLengthRule(maxLength: 1000),
                TieredStatementAdjustmentLabelLengthRule(maxLength: 86400),
                TieredStatementAdjustmentRequiredCodeRule(message: "tiered statement adjustment needs an entry"),
                TieredStatementAdjustmentCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
