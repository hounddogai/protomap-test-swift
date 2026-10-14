import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global worklist override must pass. Check returns its problems, or none.
    protocol GlobalWorklistOverrideRule {
        func check(_ item: GlobalWorklistOverride) -> [String]
    }

    final class GlobalWorklistOverrideRetriesRangeRule: GlobalWorklistOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalWorklistOverride) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalWorklistOverrideRequiredLabelRule: GlobalWorklistOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalWorklistOverride) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalWorklistOverrideRequiredCodeRule: GlobalWorklistOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalWorklistOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalWorklistOverrideRequiredChecksumRule: GlobalWorklistOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalWorklistOverride) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalWorklistOverrideCodeLengthRule: GlobalWorklistOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalWorklistOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalWorklistOverrideRequiredTimezoneRule: GlobalWorklistOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalWorklistOverride) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global worklist override.
    final class GlobalWorklistOverrideValidator {
        var rules: [any GlobalWorklistOverrideRule]

        init(rules: [any GlobalWorklistOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalWorklistOverride) -> [String] {
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

        func requireValid(_ item: GlobalWorklistOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalWorklistOverride]) -> [String: [String]] {
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

    static func defaultGlobalWorklistOverrideValidator() -> GlobalWorklistOverrideValidator {
        return GlobalWorklistOverrideValidator(
            rules: [
                GlobalWorklistOverrideRetriesRangeRule(min: 80, max: 86400),
                GlobalWorklistOverrideRequiredLabelRule(message: "global worklist override needs an entry"),
                GlobalWorklistOverrideRequiredCodeRule(message: "global worklist override needs a value"),
                GlobalWorklistOverrideRequiredChecksumRule(message: "global worklist override needs a value"),
                GlobalWorklistOverrideCodeLengthRule(maxLength: 120),
                GlobalWorklistOverrideRequiredTimezoneRule(message: "global worklist override needs an entry"),
            ]
        )
    }
}
