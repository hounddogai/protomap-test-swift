import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory preference must pass. Check returns its problems, or none.
    protocol InventoryPreferenceRule {
        func check(_ item: InventoryPreference) -> [String]
    }

    final class InventoryPreferenceNameLengthRule: InventoryPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryPreferenceStartsAtRangeRule: InventoryPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryPreference) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InventoryPreferencePayerLengthRule: InventoryPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryPreference) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryPreferenceCodePrefixRule: InventoryPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventoryPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InventoryPreferenceAllowedCodeRule: InventoryPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventoryPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class InventoryPreferenceRequiredCodeRule: InventoryPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a inventory preference.
    final class InventoryPreferenceValidator {
        var rules: [any InventoryPreferenceRule]

        init(rules: [any InventoryPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryPreference]) -> [String: [String]] {
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

    static func defaultInventoryPreferenceValidator() -> InventoryPreferenceValidator {
        return InventoryPreferenceValidator(
            rules: [
                InventoryPreferenceNameLengthRule(maxLength: 1000),
                InventoryPreferenceStartsAtRangeRule(min: 120, max: 3600),
                InventoryPreferencePayerLengthRule(maxLength: 120),
                InventoryPreferenceCodePrefixRule(prefix: "REF"),
                InventoryPreferenceAllowedCodeRule(allowed: ["regional", "legacy", "scheduled"]),
                InventoryPreferenceRequiredCodeRule(message: "inventory preference needs an entry"),
            ]
        )
    }
}
