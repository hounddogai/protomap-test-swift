import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer slot must pass. Check returns its problems, or none.
    protocol TransferSlotRule {
        func check(_ item: TransferSlot) -> [String]
    }

    final class TransferSlotAllowedOwnerIDRule: TransferSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is duplicated"]
            }
            return []
        }
    }

    final class TransferSlotBedLengthRule: TransferSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferSlot) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferSlotRefillsRangeRule: TransferSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferSlot) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferSlotTitleLengthRule: TransferSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferSlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferSlotQuantityRangeRule: TransferSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferSlot) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a transfer slot.
    final class TransferSlotValidator {
        var rules: [any TransferSlotRule]

        init(rules: [any TransferSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferSlot) -> [String] {
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

        func requireValid(_ item: TransferSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferSlot]) -> [String: [String]] {
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

    static func defaultTransferSlotValidator() -> TransferSlotValidator {
        return TransferSlotValidator(
            rules: [
                TransferSlotAllowedOwnerIDRule(allowed: ["batched"]),
                TransferSlotBedLengthRule(maxLength: 1000),
                TransferSlotRefillsRangeRule(min: 255, max: 1000),
                TransferSlotTitleLengthRule(maxLength: 16),
                TransferSlotQuantityRangeRule(min: 80, max: 80),
            ]
        )
    }
}
