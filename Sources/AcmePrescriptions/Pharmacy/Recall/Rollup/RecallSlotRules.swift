import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall slot must pass. Check returns its problems, or none.
    protocol RecallSlotRule {
        func check(_ item: RecallSlot) -> [String]
    }

    final class RecallSlotOwnerIDLengthRule: RecallSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallSlot) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallSlotMinimumRangeRule: RecallSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallSlot) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallSlotCodePrefixRule: RecallSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RecallSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RecallSlotNameLengthRule: RecallSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallSlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallSlotFloorValueRangeRule: RecallSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallSlot) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallSlotRequiredNameRule: RecallSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallSlot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall slot.
    final class RecallSlotValidator {
        var rules: [any RecallSlotRule]

        init(rules: [any RecallSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallSlot]) -> [String: [String]] {
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

    static func defaultRecallSlotValidator() -> RecallSlotValidator {
        return RecallSlotValidator(
            rules: [
                RecallSlotOwnerIDLengthRule(maxLength: 255),
                RecallSlotMinimumRangeRule(min: 4.4, max: 4029.6),
                RecallSlotCodePrefixRule(prefix: "X"),
                RecallSlotNameLengthRule(maxLength: 86400),
                RecallSlotFloorValueRangeRule(min: 5.0, max: 1101.8),
                RecallSlotRequiredNameRule(message: "recall slot needs an entry"),
            ]
        )
    }
}
