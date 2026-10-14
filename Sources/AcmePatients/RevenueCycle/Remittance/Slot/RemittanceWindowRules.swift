import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance window must pass. Check returns its problems, or none.
    protocol RemittanceWindowRule {
        func check(_ item: RemittanceWindow) -> [String]
    }

    final class RemittanceWindowCodePrefixRule: RemittanceWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RemittanceWindowRequiredCodeRule: RemittanceWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceWindowAmountRangeRule: RemittanceWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceWindow) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RemittanceWindowCodeLengthRule: RemittanceWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceWindowRequiredCategoryRule: RemittanceWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceWindow) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceWindowRequiredOwnerIDRule: RemittanceWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceWindow) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a remittance window.
    final class RemittanceWindowValidator {
        var rules: [any RemittanceWindowRule]

        init(rules: [any RemittanceWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceWindow) -> [String] {
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

        func requireValid(_ item: RemittanceWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceWindow]) -> [String: [String]] {
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

    static func defaultRemittanceWindowValidator() -> RemittanceWindowValidator {
        return RemittanceWindowValidator(
            rules: [
                RemittanceWindowCodePrefixRule(prefix: "X"),
                RemittanceWindowRequiredCodeRule(message: "remittance window needs a value"),
                RemittanceWindowAmountRangeRule(min: 7.0, max: 2943.8),
                RemittanceWindowCodeLengthRule(maxLength: 120),
                RemittanceWindowRequiredCategoryRule(message: "remittance window needs this field"),
                RemittanceWindowRequiredOwnerIDRule(message: "remittance window needs this field"),
            ]
        )
    }
}
