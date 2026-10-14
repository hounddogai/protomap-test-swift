import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched charge entry must pass. Check returns its problems, or none.
    protocol BatchedChargeEntryRule {
        func check(_ item: BatchedChargeEntry) -> [String]
    }

    final class BatchedChargeEntryRequiredContactEmailRule: BatchedChargeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedChargeEntry) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedChargeEntryQuantityRangeRule: BatchedChargeEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedChargeEntry) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedChargeEntryRequiredNameRule: BatchedChargeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedChargeEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedChargeEntryAllowedCodeRule: BatchedChargeEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedChargeEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class BatchedChargeEntryLabelLengthRule: BatchedChargeEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedChargeEntry) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedChargeEntryRequiredCodeRule: BatchedChargeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedChargeEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched charge entry.
    final class BatchedChargeEntryValidator {
        var rules: [any BatchedChargeEntryRule]

        init(rules: [any BatchedChargeEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedChargeEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedChargeEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedChargeEntry]) -> [String: [String]] {
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

    static func defaultBatchedChargeEntryValidator() -> BatchedChargeEntryValidator {
        return BatchedChargeEntryValidator(
            rules: [
                BatchedChargeEntryRequiredContactEmailRule(message: "batched charge entry needs a value"),
                BatchedChargeEntryQuantityRangeRule(min: 16, max: 80),
                BatchedChargeEntryRequiredNameRule(message: "batched charge entry needs this field"),
                BatchedChargeEntryAllowedCodeRule(allowed: ["fallback", "fallback"]),
                BatchedChargeEntryLabelLengthRule(maxLength: 16),
                BatchedChargeEntryRequiredCodeRule(message: "batched charge entry needs this field"),
            ]
        )
    }
}
