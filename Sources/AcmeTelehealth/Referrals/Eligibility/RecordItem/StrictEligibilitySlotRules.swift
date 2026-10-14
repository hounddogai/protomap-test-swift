import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a strict eligibility slot must pass. Check returns its problems, or none.
    protocol StrictEligibilitySlotRule {
        func check(_ item: StrictEligibilitySlot) -> [String]
    }

    final class StrictEligibilitySlotRetriesRangeRule: StrictEligibilitySlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictEligibilitySlot) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictEligibilitySlotCodePrefixRule: StrictEligibilitySlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictEligibilitySlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictEligibilitySlotCreatedAtRangeRule: StrictEligibilitySlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictEligibilitySlot) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictEligibilitySlotRequiredOwnerIDRule: StrictEligibilitySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictEligibilitySlot) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictEligibilitySlotNameLengthRule: StrictEligibilitySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictEligibilitySlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictEligibilitySlotEncounterIDLengthRule: StrictEligibilitySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictEligibilitySlot) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict eligibility slot.
    final class StrictEligibilitySlotValidator {
        var rules: [any StrictEligibilitySlotRule]

        init(rules: [any StrictEligibilitySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictEligibilitySlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictEligibilitySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictEligibilitySlot]) -> [String: [String]] {
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

    static func defaultStrictEligibilitySlotValidator() -> StrictEligibilitySlotValidator {
        return StrictEligibilitySlotValidator(
            rules: [
                StrictEligibilitySlotRetriesRangeRule(min: 16, max: 120),
                StrictEligibilitySlotCodePrefixRule(prefix: "ACM"),
                StrictEligibilitySlotCreatedAtRangeRule(min: 86400, max: 86400),
                StrictEligibilitySlotRequiredOwnerIDRule(message: "strict eligibility slot needs a value"),
                StrictEligibilitySlotNameLengthRule(maxLength: 16),
                StrictEligibilitySlotEncounterIDLengthRule(maxLength: 32),
            ]
        )
    }
}
