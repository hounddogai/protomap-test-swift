import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched slot tier must pass. Check returns its problems, or none.
    protocol BatchedSlotTierRule {
        func check(_ item: BatchedSlotTier) -> [String]
    }

    final class BatchedSlotTierExpiresAtRangeRule: BatchedSlotTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSlotTier) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedSlotTierTitleLengthRule: BatchedSlotTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSlotTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSlotTierRequiredCodeRule: BatchedSlotTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSlotTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedSlotTierLocaleLengthRule: BatchedSlotTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSlotTier) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSlotTierCodePrefixRule: BatchedSlotTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedSlotTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched slot tier.
    final class BatchedSlotTierValidator {
        var rules: [any BatchedSlotTierRule]

        init(rules: [any BatchedSlotTierRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSlotTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedSlotTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSlotTier]) -> [String: [String]] {
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

    static func defaultBatchedSlotTierValidator() -> BatchedSlotTierValidator {
        return BatchedSlotTierValidator(
            rules: [
                BatchedSlotTierExpiresAtRangeRule(min: 80, max: 3600),
                BatchedSlotTierTitleLengthRule(maxLength: 255),
                BatchedSlotTierRequiredCodeRule(message: "batched slot tier needs an entry"),
                BatchedSlotTierLocaleLengthRule(maxLength: 3600),
                BatchedSlotTierCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
