import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer allocation must pass. Check returns its problems, or none.
    protocol TransferAllocationRule {
        func check(_ item: TransferAllocation) -> [String]
    }

    final class TransferAllocationRequiredCodeRule: TransferAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferAllocationScoreRangeRule: TransferAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferAllocation) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferAllocationCodeLengthRule: TransferAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferAllocationQuantityRangeRule: TransferAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferAllocation) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferAllocationCodePrefixRule: TransferAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TransferAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TransferAllocationRequiredPayerRule: TransferAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferAllocation) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer allocation.
    final class TransferAllocationValidator {
        var rules: [any TransferAllocationRule]

        init(rules: [any TransferAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferAllocation) -> [String] {
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

        func requireValid(_ item: TransferAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferAllocation]) -> [String: [String]] {
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

    static func defaultTransferAllocationValidator() -> TransferAllocationValidator {
        return TransferAllocationValidator(
            rules: [
                TransferAllocationRequiredCodeRule(message: "transfer allocation needs an entry"),
                TransferAllocationScoreRangeRule(min: 1.7, max: 3860.6),
                TransferAllocationCodeLengthRule(maxLength: 120),
                TransferAllocationQuantityRangeRule(min: 120, max: 86400),
                TransferAllocationCodePrefixRule(prefix: "OPS"),
                TransferAllocationRequiredPayerRule(message: "transfer allocation needs an entry"),
            ]
        )
    }
}
