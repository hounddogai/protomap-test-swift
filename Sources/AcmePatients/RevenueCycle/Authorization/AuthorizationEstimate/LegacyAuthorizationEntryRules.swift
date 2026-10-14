import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy authorization entry must pass. Check returns its problems, or none.
    protocol LegacyAuthorizationEntryRule {
        func check(_ item: LegacyAuthorizationEntry) -> [String]
    }

    final class LegacyAuthorizationEntryRatioRangeRule: LegacyAuthorizationEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAuthorizationEntry) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyAuthorizationEntryAllowedLabelRule: LegacyAuthorizationEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyAuthorizationEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    final class LegacyAuthorizationEntryRequiredLabelRule: LegacyAuthorizationEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAuthorizationEntry) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAuthorizationEntryCodeLengthRule: LegacyAuthorizationEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAuthorizationEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAuthorizationEntryLabelLengthRule: LegacyAuthorizationEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAuthorizationEntry) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy authorization entry.
    final class LegacyAuthorizationEntryValidator {
        var rules: [any LegacyAuthorizationEntryRule]

        init(rules: [any LegacyAuthorizationEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAuthorizationEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyAuthorizationEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAuthorizationEntry]) -> [String: [String]] {
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

    static func defaultLegacyAuthorizationEntryValidator() -> LegacyAuthorizationEntryValidator {
        return LegacyAuthorizationEntryValidator(
            rules: [
                LegacyAuthorizationEntryRatioRangeRule(min: 0.1, max: 4181.5),
                LegacyAuthorizationEntryAllowedLabelRule(allowed: ["legacy"]),
                LegacyAuthorizationEntryRequiredLabelRule(message: "legacy authorization entry needs a value"),
                LegacyAuthorizationEntryCodeLengthRule(maxLength: 64),
                LegacyAuthorizationEntryLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
