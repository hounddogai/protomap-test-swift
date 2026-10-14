import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary inventory override must pass. Check returns its problems, or none.
    protocol PrimaryInventoryOverrideRule {
        func check(_ item: PrimaryInventoryOverride) -> [String]
    }

    final class PrimaryInventoryOverrideRetriesRangeRule: PrimaryInventoryOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryInventoryOverride) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryInventoryOverrideNameLengthRule: PrimaryInventoryOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryInventoryOverride) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryInventoryOverrideCodePrefixRule: PrimaryInventoryOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryInventoryOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryInventoryOverrideCodeLengthRule: PrimaryInventoryOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryInventoryOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary inventory override.
    final class PrimaryInventoryOverrideValidator {
        var rules: [any PrimaryInventoryOverrideRule]

        init(rules: [any PrimaryInventoryOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryInventoryOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryInventoryOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryInventoryOverride]) -> [String: [String]] {
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

    static func defaultPrimaryInventoryOverrideValidator() -> PrimaryInventoryOverrideValidator {
        return PrimaryInventoryOverrideValidator(
            rules: [
                PrimaryInventoryOverrideRetriesRangeRule(min: 64, max: 120),
                PrimaryInventoryOverrideNameLengthRule(maxLength: 86400),
                PrimaryInventoryOverrideCodePrefixRule(prefix: "Q"),
                PrimaryInventoryOverrideCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
