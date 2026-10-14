import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory batch must pass. Check returns its problems, or none.
    protocol InventoryBatchRule {
        func check(_ item: InventoryBatch) -> [String]
    }

    final class InventoryBatchRequiredTitleRule: InventoryBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryBatchRequiredPayerRule: InventoryBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryBatch) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryBatchAllowedTitleRule: InventoryBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventoryBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    final class InventoryBatchTitleLengthRule: InventoryBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory batch.
    final class InventoryBatchValidator {
        var rules: [any InventoryBatchRule]

        init(rules: [any InventoryBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryBatch) -> [String] {
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

        func requireValid(_ item: InventoryBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryBatch]) -> [String: [String]] {
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

    static func defaultInventoryBatchValidator() -> InventoryBatchValidator {
        return InventoryBatchValidator(
            rules: [
                InventoryBatchRequiredTitleRule(message: "inventory batch needs an entry"),
                InventoryBatchRequiredPayerRule(message: "inventory batch needs an entry"),
                InventoryBatchAllowedTitleRule(allowed: ["batched", "default"]),
                InventoryBatchTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
