import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched bed board allocation must pass. Check returns its problems, or none.
    protocol BatchedBedBoardAllocationRule {
        func check(_ item: BatchedBedBoardAllocation) -> [String]
    }

    final class BatchedBedBoardAllocationRequiredCodeRule: BatchedBedBoardAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedBedBoardAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedBedBoardAllocationRequiredLabelRule: BatchedBedBoardAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedBedBoardAllocation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedBedBoardAllocationCodePrefixRule: BatchedBedBoardAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedBedBoardAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched bed board allocation.
    final class BatchedBedBoardAllocationValidator {
        var rules: [any BatchedBedBoardAllocationRule]

        init(rules: [any BatchedBedBoardAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedBedBoardAllocation) -> [String] {
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

        func requireValid(_ item: BatchedBedBoardAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedBedBoardAllocation]) -> [String: [String]] {
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

    static func defaultBatchedBedBoardAllocationValidator() -> BatchedBedBoardAllocationValidator {
        return BatchedBedBoardAllocationValidator(
            rules: [
                BatchedBedBoardAllocationRequiredCodeRule(message: "batched bed board allocation needs a value"),
                BatchedBedBoardAllocationRequiredLabelRule(message: "batched bed board allocation needs an entry"),
                BatchedBedBoardAllocationCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
