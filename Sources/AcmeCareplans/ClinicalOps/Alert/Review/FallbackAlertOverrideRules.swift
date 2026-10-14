import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback alert override must pass. Check returns its problems, or none.
    protocol FallbackAlertOverrideRule {
        func check(_ item: FallbackAlertOverride) -> [String]
    }

    final class FallbackAlertOverrideRequiredCodeRule: FallbackAlertOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAlertOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAlertOverrideRefillsRangeRule: FallbackAlertOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackAlertOverride) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackAlertOverrideCodeLengthRule: FallbackAlertOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAlertOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAlertOverrideRequiredTitleRule: FallbackAlertOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAlertOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback alert override.
    final class FallbackAlertOverrideValidator {
        var rules: [any FallbackAlertOverrideRule]

        init(rules: [any FallbackAlertOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackAlertOverride) -> [String] {
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

        func requireValid(_ item: FallbackAlertOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackAlertOverride]) -> [String: [String]] {
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

    static func defaultFallbackAlertOverrideValidator() -> FallbackAlertOverrideValidator {
        return FallbackAlertOverrideValidator(
            rules: [
                FallbackAlertOverrideRequiredCodeRule(message: "fallback alert override needs a value"),
                FallbackAlertOverrideRefillsRangeRule(min: 80, max: 255),
                FallbackAlertOverrideCodeLengthRule(maxLength: 64),
                FallbackAlertOverrideRequiredTitleRule(message: "fallback alert override needs a value"),
            ]
        )
    }
}
