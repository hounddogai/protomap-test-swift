import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory threshold must pass. Check returns its problems, or none.
    protocol InventoryThresholdRule {
        func check(_ item: InventoryThreshold) -> [String]
    }

    final class InventoryThresholdRequiredTitleRule: InventoryThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryThresholdAllowedCurrencyRule: InventoryThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventoryThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is not allowed"]
            }
            return []
        }
    }

    final class InventoryThresholdTitleLengthRule: InventoryThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryThresholdCurrencyLengthRule: InventoryThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryThreshold) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryThresholdCodePrefixRule: InventoryThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventoryThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory threshold.
    final class InventoryThresholdValidator {
        var rules: [any InventoryThresholdRule]

        init(rules: [any InventoryThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryThreshold]) -> [String: [String]] {
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

    static func defaultInventoryThresholdValidator() -> InventoryThresholdValidator {
        return InventoryThresholdValidator(
            rules: [
                InventoryThresholdRequiredTitleRule(message: "inventory threshold needs this field"),
                InventoryThresholdAllowedCurrencyRule(allowed: []),
                InventoryThresholdTitleLengthRule(maxLength: 3600),
                InventoryThresholdCurrencyLengthRule(maxLength: 32),
                InventoryThresholdCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
