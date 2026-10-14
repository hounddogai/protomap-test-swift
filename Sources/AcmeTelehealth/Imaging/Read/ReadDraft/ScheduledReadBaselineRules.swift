import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled read baseline must pass. Check returns its problems, or none.
    protocol ScheduledReadBaselineRule {
        func check(_ item: ScheduledReadBaseline) -> [String]
    }

    final class ScheduledReadBaselineAllowedUnitRule: ScheduledReadBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledReadBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is duplicated"]
            }
            return []
        }
    }

    final class ScheduledReadBaselineRequiredTitleRule: ScheduledReadBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledReadBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledReadBaselineRequiredSummaryRule: ScheduledReadBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledReadBaseline) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledReadBaselineSummaryLengthRule: ScheduledReadBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledReadBaseline) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledReadBaselineWindowDaysRangeRule: ScheduledReadBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledReadBaseline) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledReadBaselineCodePrefixRule: ScheduledReadBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledReadBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled read baseline.
    final class ScheduledReadBaselineValidator {
        var rules: [any ScheduledReadBaselineRule]

        init(rules: [any ScheduledReadBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledReadBaseline) -> [String] {
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

        func requireValid(_ item: ScheduledReadBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledReadBaseline]) -> [String: [String]] {
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

    static func defaultScheduledReadBaselineValidator() -> ScheduledReadBaselineValidator {
        return ScheduledReadBaselineValidator(
            rules: [
                ScheduledReadBaselineAllowedUnitRule(allowed: []),
                ScheduledReadBaselineRequiredTitleRule(message: "scheduled read baseline needs an entry"),
                ScheduledReadBaselineRequiredSummaryRule(message: "scheduled read baseline needs a value"),
                ScheduledReadBaselineSummaryLengthRule(maxLength: 255),
                ScheduledReadBaselineWindowDaysRangeRule(min: 120, max: 255),
                ScheduledReadBaselineCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
