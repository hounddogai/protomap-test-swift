import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance rollup must pass. Check returns its problems, or none.
    protocol RemittanceRollupRule {
        func check(_ item: RemittanceRollup) -> [String]
    }

    final class RemittanceRollupPriorityRangeRule: RemittanceRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceRollup) -> [String] {
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

    final class RemittanceRollupRequiredTimezoneRule: RemittanceRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceRollup) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceRollupCodePrefixRule: RemittanceRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RemittanceRollupNameLengthRule: RemittanceRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceRollupTimezoneLengthRule: RemittanceRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceRollup) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceRollupRefillsRangeRule: RemittanceRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceRollup) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance rollup.
    final class RemittanceRollupValidator {
        var rules: [any RemittanceRollupRule]

        init(rules: [any RemittanceRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceRollup) -> [String] {
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

        func requireValid(_ item: RemittanceRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceRollup]) -> [String: [String]] {
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

    static func defaultRemittanceRollupValidator() -> RemittanceRollupValidator {
        return RemittanceRollupValidator(
            rules: [
                RemittanceRollupPriorityRangeRule(min: 1000, max: 86400),
                RemittanceRollupRequiredTimezoneRule(message: "remittance rollup needs an entry"),
                RemittanceRollupCodePrefixRule(prefix: "X"),
                RemittanceRollupNameLengthRule(maxLength: 16),
                RemittanceRollupTimezoneLengthRule(maxLength: 16),
                RemittanceRollupRefillsRangeRule(min: 255, max: 255),
            ]
        )
    }
}
