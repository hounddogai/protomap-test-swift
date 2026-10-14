import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a weighted transfer slot must pass. Check returns its problems, or none.
    protocol WeightedTransferSlotRule {
        func check(_ item: WeightedTransferSlot) -> [String]
    }

    final class WeightedTransferSlotCodeLengthRule: WeightedTransferSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedTransferSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedTransferSlotAllowedNameRule: WeightedTransferSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedTransferSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is blocked"]
            }
            return []
        }
    }

    final class WeightedTransferSlotStartsAtRangeRule: WeightedTransferSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedTransferSlot) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedTransferSlotPayerLengthRule: WeightedTransferSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedTransferSlot) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedTransferSlotRequiredPatientRefRule: WeightedTransferSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTransferSlot) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTransferSlotRequiredPayerRule: WeightedTransferSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTransferSlot) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted transfer slot.
    final class WeightedTransferSlotValidator {
        var rules: [any WeightedTransferSlotRule]

        init(rules: [any WeightedTransferSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedTransferSlot) -> [String] {
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

        func requireValid(_ item: WeightedTransferSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedTransferSlot]) -> [String: [String]] {
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

    static func defaultWeightedTransferSlotValidator() -> WeightedTransferSlotValidator {
        return WeightedTransferSlotValidator(
            rules: [
                WeightedTransferSlotCodeLengthRule(maxLength: 86400),
                WeightedTransferSlotAllowedNameRule(allowed: []),
                WeightedTransferSlotStartsAtRangeRule(min: 16, max: 1000),
                WeightedTransferSlotPayerLengthRule(maxLength: 32),
                WeightedTransferSlotRequiredPatientRefRule(message: "weighted transfer slot needs a value"),
                WeightedTransferSlotRequiredPayerRule(message: "weighted transfer slot needs this field"),
            ]
        )
    }
}
