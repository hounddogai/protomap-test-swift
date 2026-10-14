import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set slot must pass. Check returns its problems, or none.
    protocol OrderSetSlotRule {
        func check(_ item: OrderSetSlot) -> [String]
    }

    final class OrderSetSlotCodePrefixRule: OrderSetSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OrderSetSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OrderSetSlotPinnedGuardRule: OrderSetSlotRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: OrderSetSlot) -> [String] {
            if item.pinned && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class OrderSetSlotRequiredCodeRule: OrderSetSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set slot.
    final class OrderSetSlotValidator {
        var rules: [any OrderSetSlotRule]

        init(rules: [any OrderSetSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetSlot) -> [String] {
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

        func requireValid(_ item: OrderSetSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetSlot]) -> [String: [String]] {
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

    static func defaultOrderSetSlotValidator() -> OrderSetSlotValidator {
        return OrderSetSlotValidator(
            rules: [
                OrderSetSlotCodePrefixRule(prefix: "Q"),
                OrderSetSlotPinnedGuardRule(limit: 3600),
                OrderSetSlotRequiredCodeRule(message: "order set slot needs this field"),
            ]
        )
    }
}
