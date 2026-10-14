import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched inventory policy must pass. Check returns its problems, or none.
    protocol BatchedInventoryPolicyRule {
        func check(_ item: BatchedInventoryPolicy) -> [String]
    }

    final class BatchedInventoryPolicyCodeLengthRule: BatchedInventoryPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedInventoryPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedInventoryPolicyRequiredNameRule: BatchedInventoryPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedInventoryPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedInventoryPolicyRequiredSourceRule: BatchedInventoryPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedInventoryPolicy) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched inventory policy.
    final class BatchedInventoryPolicyValidator {
        var rules: [any BatchedInventoryPolicyRule]

        init(rules: [any BatchedInventoryPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedInventoryPolicy) -> [String] {
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

        func requireValid(_ item: BatchedInventoryPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedInventoryPolicy]) -> [String: [String]] {
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

    static func defaultBatchedInventoryPolicyValidator() -> BatchedInventoryPolicyValidator {
        return BatchedInventoryPolicyValidator(
            rules: [
                BatchedInventoryPolicyCodeLengthRule(maxLength: 32),
                BatchedInventoryPolicyRequiredNameRule(message: "batched inventory policy needs this field"),
                BatchedInventoryPolicyRequiredSourceRule(message: "batched inventory policy needs a value"),
            ]
        )
    }
}
