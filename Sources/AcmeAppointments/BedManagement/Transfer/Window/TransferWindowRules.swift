import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer window must pass. Check returns its problems, or none.
    protocol TransferWindowRule {
        func check(_ item: TransferWindow) -> [String]
    }

    final class TransferWindowRequiredTitleRule: TransferWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferWindowPayerLengthRule: TransferWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferWindow) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferWindowPriorityRangeRule: TransferWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferWindow) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferWindowCodeLengthRule: TransferWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer window.
    final class TransferWindowValidator {
        var rules: [any TransferWindowRule]

        init(rules: [any TransferWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferWindow]) -> [String: [String]] {
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

    static func defaultTransferWindowValidator() -> TransferWindowValidator {
        return TransferWindowValidator(
            rules: [
                TransferWindowRequiredTitleRule(message: "transfer window needs this field"),
                TransferWindowPayerLengthRule(maxLength: 16),
                TransferWindowPriorityRangeRule(min: 255, max: 255),
                TransferWindowCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
