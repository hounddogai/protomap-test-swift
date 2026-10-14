import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary handoff slot must pass. Check returns its problems, or none.
    protocol PrimaryHandoffSlotRule {
        func check(_ item: PrimaryHandoffSlot) -> [String]
    }

    final class PrimaryHandoffSlotRequiredProcedureCodeRule: PrimaryHandoffSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryHandoffSlot) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryHandoffSlotNameLengthRule: PrimaryHandoffSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryHandoffSlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryHandoffSlotRefillsRangeRule: PrimaryHandoffSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryHandoffSlot) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryHandoffSlotCodePrefixRule: PrimaryHandoffSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryHandoffSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryHandoffSlotRequiredCodeRule: PrimaryHandoffSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryHandoffSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryHandoffSlotAllowedNameRule: PrimaryHandoffSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryHandoffSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a primary handoff slot.
    final class PrimaryHandoffSlotValidator {
        var rules: [any PrimaryHandoffSlotRule]

        init(rules: [any PrimaryHandoffSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryHandoffSlot) -> [String] {
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

        func requireValid(_ item: PrimaryHandoffSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryHandoffSlot]) -> [String: [String]] {
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

    static func defaultPrimaryHandoffSlotValidator() -> PrimaryHandoffSlotValidator {
        return PrimaryHandoffSlotValidator(
            rules: [
                PrimaryHandoffSlotRequiredProcedureCodeRule(message: "primary handoff slot needs a value"),
                PrimaryHandoffSlotNameLengthRule(maxLength: 64),
                PrimaryHandoffSlotRefillsRangeRule(min: 32, max: 3600),
                PrimaryHandoffSlotCodePrefixRule(prefix: "Q"),
                PrimaryHandoffSlotRequiredCodeRule(message: "primary handoff slot needs an entry"),
                PrimaryHandoffSlotAllowedNameRule(allowed: ["rolling", "capped"]),
            ]
        )
    }
}
