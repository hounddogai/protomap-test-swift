import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict claim summary must pass. Check returns its problems, or none.
    protocol StrictClaimSummaryRule {
        func check(_ item: StrictClaimSummary) -> [String]
    }

    final class StrictClaimSummaryUpdatedAtRangeRule: StrictClaimSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictClaimSummary) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictClaimSummaryCodePrefixRule: StrictClaimSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictClaimSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictClaimSummaryStartsAtRangeRule: StrictClaimSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictClaimSummary) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictClaimSummaryTitleLengthRule: StrictClaimSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictClaimSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictClaimSummaryRequiredSummaryRule: StrictClaimSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictClaimSummary) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictClaimSummaryRequiredTitleRule: StrictClaimSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictClaimSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict claim summary.
    final class StrictClaimSummaryValidator {
        var rules: [any StrictClaimSummaryRule]

        init(rules: [any StrictClaimSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictClaimSummary) -> [String] {
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

        func requireValid(_ item: StrictClaimSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictClaimSummary]) -> [String: [String]] {
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

    static func defaultStrictClaimSummaryValidator() -> StrictClaimSummaryValidator {
        return StrictClaimSummaryValidator(
            rules: [
                StrictClaimSummaryUpdatedAtRangeRule(min: 16, max: 3600),
                StrictClaimSummaryCodePrefixRule(prefix: "X"),
                StrictClaimSummaryStartsAtRangeRule(min: 255, max: 1000),
                StrictClaimSummaryTitleLengthRule(maxLength: 86400),
                StrictClaimSummaryRequiredSummaryRule(message: "strict claim summary needs a value"),
                StrictClaimSummaryRequiredTitleRule(message: "strict claim summary needs this field"),
            ]
        )
    }
}
