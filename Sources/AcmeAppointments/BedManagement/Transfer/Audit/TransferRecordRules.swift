import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer record must pass. Check returns its problems, or none.
    protocol TransferRecordRule {
        func check(_ item: TransferRecord) -> [String]
    }

    final class TransferRecordRequiredLabelRule: TransferRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferRecordCodeLengthRule: TransferRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferRecordRequiredCodeRule: TransferRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferRecordAttemptsRangeRule: TransferRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferRecord) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferRecordCodePrefixRule: TransferRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TransferRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer record.
    final class TransferRecordValidator {
        var rules: [any TransferRecordRule]

        init(rules: [any TransferRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferRecord]) -> [String: [String]] {
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

    static func defaultTransferRecordValidator() -> TransferRecordValidator {
        return TransferRecordValidator(
            rules: [
                TransferRecordRequiredLabelRule(message: "transfer record needs an entry"),
                TransferRecordCodeLengthRule(maxLength: 80),
                TransferRecordRequiredCodeRule(message: "transfer record needs a value"),
                TransferRecordAttemptsRangeRule(min: 64, max: 255),
                TransferRecordCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
