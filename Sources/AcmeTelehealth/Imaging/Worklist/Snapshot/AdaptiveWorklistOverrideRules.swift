import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive worklist override must pass. Check returns its problems, or none.
    protocol AdaptiveWorklistOverrideRule {
        func check(_ item: AdaptiveWorklistOverride) -> [String]
    }

    final class AdaptiveWorklistOverrideCodePrefixRule: AdaptiveWorklistOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveWorklistOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveWorklistOverrideRequiredCodeRule: AdaptiveWorklistOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveWorklistOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveWorklistOverrideDurationMinutesRangeRule: AdaptiveWorklistOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveWorklistOverride) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveWorklistOverrideRequiredNotesRule: AdaptiveWorklistOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveWorklistOverride) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive worklist override.
    final class AdaptiveWorklistOverrideValidator {
        var rules: [any AdaptiveWorklistOverrideRule]

        init(rules: [any AdaptiveWorklistOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveWorklistOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveWorklistOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveWorklistOverride]) -> [String: [String]] {
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

    static func defaultAdaptiveWorklistOverrideValidator() -> AdaptiveWorklistOverrideValidator {
        return AdaptiveWorklistOverrideValidator(
            rules: [
                AdaptiveWorklistOverrideCodePrefixRule(prefix: "X"),
                AdaptiveWorklistOverrideRequiredCodeRule(message: "adaptive worklist override needs an entry"),
                AdaptiveWorklistOverrideDurationMinutesRangeRule(min: 120, max: 86400),
                AdaptiveWorklistOverrideRequiredNotesRule(message: "adaptive worklist override needs an entry"),
            ]
        )
    }
}
