import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled closure rollup must pass. Check returns its problems, or none.
    protocol ScheduledClosureRollupRule {
        func check(_ item: ScheduledClosureRollup) -> [String]
    }

    final class ScheduledClosureRollupAllowedTitleRule: ScheduledClosureRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledClosureRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    final class ScheduledClosureRollupTitleLengthRule: ScheduledClosureRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledClosureRollup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledClosureRollupCodePrefixRule: ScheduledClosureRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledClosureRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledClosureRollupRequiredTitleRule: ScheduledClosureRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledClosureRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledClosureRollupWeightRangeRule: ScheduledClosureRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledClosureRollup) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled closure rollup.
    final class ScheduledClosureRollupValidator {
        var rules: [any ScheduledClosureRollupRule]

        init(rules: [any ScheduledClosureRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledClosureRollup) -> [String] {
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

        func requireValid(_ item: ScheduledClosureRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledClosureRollup]) -> [String: [String]] {
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

    static func defaultScheduledClosureRollupValidator() -> ScheduledClosureRollupValidator {
        return ScheduledClosureRollupValidator(
            rules: [
                ScheduledClosureRollupAllowedTitleRule(allowed: []),
                ScheduledClosureRollupTitleLengthRule(maxLength: 86400),
                ScheduledClosureRollupCodePrefixRule(prefix: "REF"),
                ScheduledClosureRollupRequiredTitleRule(message: "scheduled closure rollup needs a value"),
                ScheduledClosureRollupWeightRangeRule(min: 5.3, max: 4932.9),
            ]
        )
    }
}
