import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered task override must pass. Check returns its problems, or none.
    protocol TieredTaskOverrideRule {
        func check(_ item: TieredTaskOverride) -> [String]
    }

    final class TieredTaskOverrideTimezoneLengthRule: TieredTaskOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredTaskOverride) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredTaskOverrideAttemptsRangeRule: TieredTaskOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredTaskOverride) -> [String] {
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

    final class TieredTaskOverrideRequiredLabelRule: TieredTaskOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredTaskOverride) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredTaskOverrideCodePrefixRule: TieredTaskOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredTaskOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered task override.
    final class TieredTaskOverrideValidator {
        var rules: [any TieredTaskOverrideRule]

        init(rules: [any TieredTaskOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredTaskOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredTaskOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredTaskOverride]) -> [String: [String]] {
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

    static func defaultTieredTaskOverrideValidator() -> TieredTaskOverrideValidator {
        return TieredTaskOverrideValidator(
            rules: [
                TieredTaskOverrideTimezoneLengthRule(maxLength: 3600),
                TieredTaskOverrideAttemptsRangeRule(min: 80, max: 1000),
                TieredTaskOverrideRequiredLabelRule(message: "tiered task override needs this field"),
                TieredTaskOverrideCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
