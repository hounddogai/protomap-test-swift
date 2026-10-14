import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending eligibility slot must pass. Check returns its problems, or none.
    protocol PendingEligibilitySlotRule {
        func check(_ item: PendingEligibilitySlot) -> [String]
    }

    final class PendingEligibilitySlotFloorValueRangeRule: PendingEligibilitySlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingEligibilitySlot) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingEligibilitySlotRequiredProcedureCodeRule: PendingEligibilitySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingEligibilitySlot) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingEligibilitySlotTitleLengthRule: PendingEligibilitySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingEligibilitySlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingEligibilitySlotRequiredLabelRule: PendingEligibilitySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingEligibilitySlot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingEligibilitySlotProcedureCodeLengthRule: PendingEligibilitySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingEligibilitySlot) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingEligibilitySlotCodePrefixRule: PendingEligibilitySlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingEligibilitySlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending eligibility slot.
    final class PendingEligibilitySlotValidator {
        var rules: [any PendingEligibilitySlotRule]

        init(rules: [any PendingEligibilitySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingEligibilitySlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingEligibilitySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingEligibilitySlot]) -> [String: [String]] {
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

    static func defaultPendingEligibilitySlotValidator() -> PendingEligibilitySlotValidator {
        return PendingEligibilitySlotValidator(
            rules: [
                PendingEligibilitySlotFloorValueRangeRule(min: 5.9, max: 1628.2),
                PendingEligibilitySlotRequiredProcedureCodeRule(message: "pending eligibility slot needs a value"),
                PendingEligibilitySlotTitleLengthRule(maxLength: 86400),
                PendingEligibilitySlotRequiredLabelRule(message: "pending eligibility slot needs a value"),
                PendingEligibilitySlotProcedureCodeLengthRule(maxLength: 120),
                PendingEligibilitySlotCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
