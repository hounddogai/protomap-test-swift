import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched inventory baseline must pass. Check returns its problems, or none.
    protocol BatchedInventoryBaselineRule {
        func check(_ item: BatchedInventoryBaseline) -> [String]
    }

    final class BatchedInventoryBaselineContactEmailLengthRule: BatchedInventoryBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedInventoryBaseline) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedInventoryBaselineRequiredSummaryRule: BatchedInventoryBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedInventoryBaseline) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedInventoryBaselineCodeLengthRule: BatchedInventoryBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedInventoryBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedInventoryBaselineAllowedSummaryRule: BatchedInventoryBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedInventoryBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is blocked"]
            }
            return []
        }
    }

    final class BatchedInventoryBaselineRequiredLabelRule: BatchedInventoryBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedInventoryBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedInventoryBaselineMinimumRangeRule: BatchedInventoryBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedInventoryBaseline) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched inventory baseline.
    final class BatchedInventoryBaselineValidator {
        var rules: [any BatchedInventoryBaselineRule]

        init(rules: [any BatchedInventoryBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedInventoryBaseline) -> [String] {
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

        func requireValid(_ item: BatchedInventoryBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedInventoryBaseline]) -> [String: [String]] {
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

    static func defaultBatchedInventoryBaselineValidator() -> BatchedInventoryBaselineValidator {
        return BatchedInventoryBaselineValidator(
            rules: [
                BatchedInventoryBaselineContactEmailLengthRule(maxLength: 16),
                BatchedInventoryBaselineRequiredSummaryRule(message: "batched inventory baseline needs a value"),
                BatchedInventoryBaselineCodeLengthRule(maxLength: 3600),
                BatchedInventoryBaselineAllowedSummaryRule(allowed: ["pending"]),
                BatchedInventoryBaselineRequiredLabelRule(message: "batched inventory baseline needs this field"),
                BatchedInventoryBaselineMinimumRangeRule(min: 1.2, max: 3347.4),
            ]
        )
    }
}
