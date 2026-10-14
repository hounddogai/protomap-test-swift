import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot item must pass. Check returns its problems, or none.
    protocol SlotItemRule {
        func check(_ item: SlotItem) -> [String]
    }

    final class SlotItemAllowedLabelRule: SlotItemRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SlotItem) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is duplicated"]
            }
            return []
        }
    }

    final class SlotItemRequiredProcedureCodeRule: SlotItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotItem) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotItemCodePrefixRule: SlotItemRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotItem) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SlotItemCodeLengthRule: SlotItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotItem) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot item.
    final class SlotItemValidator {
        var rules: [any SlotItemRule]

        init(rules: [any SlotItemRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotItem) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotItem) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotItem]) -> [String: [String]] {
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

    static func defaultSlotItemValidator() -> SlotItemValidator {
        return SlotItemValidator(
            rules: [
                SlotItemAllowedLabelRule(allowed: ["strict"]),
                SlotItemRequiredProcedureCodeRule(message: "slot item needs this field"),
                SlotItemCodePrefixRule(prefix: "OPS"),
                SlotItemCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
