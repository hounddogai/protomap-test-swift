import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched bed board slot must pass. Check returns its problems, or none.
    protocol BatchedBedBoardSlotRule {
        func check(_ item: BatchedBedBoardSlot) -> [String]
    }

    final class BatchedBedBoardSlotRefillsRangeRule: BatchedBedBoardSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedBedBoardSlot) -> [String] {
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

    final class BatchedBedBoardSlotBedLengthRule: BatchedBedBoardSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedBedBoardSlot) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedBedBoardSlotRequiredBedRule: BatchedBedBoardSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedBedBoardSlot) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedBedBoardSlotRequiredTitleRule: BatchedBedBoardSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedBedBoardSlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched bed board slot.
    final class BatchedBedBoardSlotValidator {
        var rules: [any BatchedBedBoardSlotRule]

        init(rules: [any BatchedBedBoardSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedBedBoardSlot) -> [String] {
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

        func requireValid(_ item: BatchedBedBoardSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedBedBoardSlot]) -> [String: [String]] {
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

    static func defaultBatchedBedBoardSlotValidator() -> BatchedBedBoardSlotValidator {
        return BatchedBedBoardSlotValidator(
            rules: [
                BatchedBedBoardSlotRefillsRangeRule(min: 1000, max: 86400),
                BatchedBedBoardSlotBedLengthRule(maxLength: 3600),
                BatchedBedBoardSlotRequiredBedRule(message: "batched bed board slot needs a value"),
                BatchedBedBoardSlotRequiredTitleRule(message: "batched bed board slot needs this field"),
            ]
        )
    }
}
