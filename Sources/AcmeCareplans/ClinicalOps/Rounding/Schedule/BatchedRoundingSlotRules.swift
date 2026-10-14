import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched rounding slot must pass. Check returns its problems, or none.
    protocol BatchedRoundingSlotRule {
        func check(_ item: BatchedRoundingSlot) -> [String]
    }

    final class BatchedRoundingSlotCodePrefixRule: BatchedRoundingSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedRoundingSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedRoundingSlotRequiredTitleRule: BatchedRoundingSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRoundingSlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedRoundingSlotRefillsRangeRule: BatchedRoundingSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedRoundingSlot) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedRoundingSlotSourceLengthRule: BatchedRoundingSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedRoundingSlot) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedRoundingSlotRequiredSourceRule: BatchedRoundingSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRoundingSlot) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedRoundingSlotRatioRangeRule: BatchedRoundingSlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedRoundingSlot) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched rounding slot.
    final class BatchedRoundingSlotValidator {
        var rules: [any BatchedRoundingSlotRule]

        init(rules: [any BatchedRoundingSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedRoundingSlot) -> [String] {
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

        func requireValid(_ item: BatchedRoundingSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedRoundingSlot]) -> [String: [String]] {
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

    static func defaultBatchedRoundingSlotValidator() -> BatchedRoundingSlotValidator {
        return BatchedRoundingSlotValidator(
            rules: [
                BatchedRoundingSlotCodePrefixRule(prefix: "ACM"),
                BatchedRoundingSlotRequiredTitleRule(message: "batched rounding slot needs a value"),
                BatchedRoundingSlotRefillsRangeRule(min: 16, max: 1000),
                BatchedRoundingSlotSourceLengthRule(maxLength: 1000),
                BatchedRoundingSlotRequiredSourceRule(message: "batched rounding slot needs a value"),
                BatchedRoundingSlotRatioRangeRule(min: 6.3, max: 4839.6),
            ]
        )
    }
}
