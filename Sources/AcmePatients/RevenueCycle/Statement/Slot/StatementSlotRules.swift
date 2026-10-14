import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement slot must pass. Check returns its problems, or none.
    protocol StatementSlotRule {
        func check(_ item: StatementSlot) -> [String]
    }

    final class StatementSlotAllowedLabelRule: StatementSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StatementSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    final class StatementSlotLabelLengthRule: StatementSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementSlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementSlotCodePrefixRule: StatementSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StatementSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StatementSlotCodeLengthRule: StatementSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementSlotVersionRangeRule: StatementSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementSlot) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement slot.
    final class StatementSlotValidator {
        var rules: [any StatementSlotRule]

        init(rules: [any StatementSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementSlot) -> [String] {
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

        func requireValid(_ item: StatementSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementSlot]) -> [String: [String]] {
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

    static func defaultStatementSlotValidator() -> StatementSlotValidator {
        return StatementSlotValidator(
            rules: [
                StatementSlotAllowedLabelRule(allowed: ["legacy", "default"]),
                StatementSlotLabelLengthRule(maxLength: 64),
                StatementSlotCodePrefixRule(prefix: "ACM"),
                StatementSlotCodeLengthRule(maxLength: 64),
                StatementSlotVersionRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
