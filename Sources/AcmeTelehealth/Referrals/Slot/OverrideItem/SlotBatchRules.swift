import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot batch must pass. Check returns its problems, or none.
    protocol SlotBatchRule {
        func check(_ item: SlotBatch) -> [String]
    }

    final class SlotBatchSourceLengthRule: SlotBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotBatch) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotBatchQuantityRangeRule: SlotBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotBatch) -> [String] {
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

    final class SlotBatchCodePrefixRule: SlotBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SlotBatchLabelLengthRule: SlotBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotBatch) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotBatchRequiredCodeRule: SlotBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a slot batch.
    final class SlotBatchValidator {
        var rules: [any SlotBatchRule]

        init(rules: [any SlotBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotBatch]) -> [String: [String]] {
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

    static func defaultSlotBatchValidator() -> SlotBatchValidator {
        return SlotBatchValidator(
            rules: [
                SlotBatchSourceLengthRule(maxLength: 3600),
                SlotBatchQuantityRangeRule(min: 255, max: 3600),
                SlotBatchCodePrefixRule(prefix: "REF"),
                SlotBatchLabelLengthRule(maxLength: 16),
                SlotBatchRequiredCodeRule(message: "slot batch needs this field"),
            ]
        )
    }
}
