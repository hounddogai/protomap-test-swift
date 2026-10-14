import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot checkpoint must pass. Check returns its problems, or none.
    protocol SlotCheckpointRule {
        func check(_ item: SlotCheckpoint) -> [String]
    }

    final class SlotCheckpointCodeLengthRule: SlotCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotCheckpointAmountRangeRule: SlotCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotCheckpoint) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotCheckpointCategoryLengthRule: SlotCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotCheckpoint) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotCheckpointOwnerIDLengthRule: SlotCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotCheckpoint) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot checkpoint.
    final class SlotCheckpointValidator {
        var rules: [any SlotCheckpointRule]

        init(rules: [any SlotCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotCheckpoint) -> [String] {
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

        func requireValid(_ item: SlotCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotCheckpoint]) -> [String: [String]] {
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

    static func defaultSlotCheckpointValidator() -> SlotCheckpointValidator {
        return SlotCheckpointValidator(
            rules: [
                SlotCheckpointCodeLengthRule(maxLength: 32),
                SlotCheckpointAmountRangeRule(min: 1.2, max: 1183.0),
                SlotCheckpointCategoryLengthRule(maxLength: 255),
                SlotCheckpointOwnerIDLengthRule(maxLength: 255),
            ]
        )
    }
}
