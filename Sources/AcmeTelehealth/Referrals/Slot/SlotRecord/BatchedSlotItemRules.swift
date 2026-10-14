import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched slot item must pass. Check returns its problems, or none.
    protocol BatchedSlotItemRule {
        func check(_ item: BatchedSlotItem) -> [String]
    }

    final class BatchedSlotItemAmountRangeRule: BatchedSlotItemRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSlotItem) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedSlotItemCodeLengthRule: BatchedSlotItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSlotItem) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSlotItemRegionLengthRule: BatchedSlotItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSlotItem) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSlotItemRequiredLabelRule: BatchedSlotItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSlotItem) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched slot item.
    final class BatchedSlotItemValidator {
        var rules: [any BatchedSlotItemRule]

        init(rules: [any BatchedSlotItemRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSlotItem) -> [String] {
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

        func requireValid(_ item: BatchedSlotItem) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSlotItem]) -> [String: [String]] {
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

    static func defaultBatchedSlotItemValidator() -> BatchedSlotItemValidator {
        return BatchedSlotItemValidator(
            rules: [
                BatchedSlotItemAmountRangeRule(min: 1.0, max: 1525.2),
                BatchedSlotItemCodeLengthRule(maxLength: 3600),
                BatchedSlotItemRegionLengthRule(maxLength: 255),
                BatchedSlotItemRequiredLabelRule(message: "batched slot item needs a value"),
            ]
        )
    }
}
