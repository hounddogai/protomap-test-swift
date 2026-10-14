import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual transfer group must pass. Check returns its problems, or none.
    protocol ManualTransferGroupRule {
        func check(_ item: ManualTransferGroup) -> [String]
    }

    final class ManualTransferGroupRequiredCodeRule: ManualTransferGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualTransferGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualTransferGroupCodeLengthRule: ManualTransferGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualTransferGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualTransferGroupCodePrefixRule: ManualTransferGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualTransferGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualTransferGroupCopayRangeRule: ManualTransferGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualTransferGroup) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual transfer group.
    final class ManualTransferGroupValidator {
        var rules: [any ManualTransferGroupRule]

        init(rules: [any ManualTransferGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualTransferGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualTransferGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualTransferGroup]) -> [String: [String]] {
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

    static func defaultManualTransferGroupValidator() -> ManualTransferGroupValidator {
        return ManualTransferGroupValidator(
            rules: [
                ManualTransferGroupRequiredCodeRule(message: "manual transfer group needs an entry"),
                ManualTransferGroupCodeLengthRule(maxLength: 80),
                ManualTransferGroupCodePrefixRule(prefix: "X"),
                ManualTransferGroupCopayRangeRule(min: 4.6, max: 3086.1),
            ]
        )
    }
}
