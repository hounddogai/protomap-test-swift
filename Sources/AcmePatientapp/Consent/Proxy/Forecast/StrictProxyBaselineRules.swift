import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict proxy baseline must pass. Check returns its problems, or none.
    protocol StrictProxyBaselineRule {
        func check(_ item: StrictProxyBaseline) -> [String]
    }

    final class StrictProxyBaselineTitleLengthRule: StrictProxyBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictProxyBaseline) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictProxyBaselineArchivedGuardRule: StrictProxyBaselineRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictProxyBaseline) -> [String] {
            if item.archived && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class StrictProxyBaselineRequiredTitleRule: StrictProxyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictProxyBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictProxyBaselineRequiredContactEmailRule: StrictProxyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictProxyBaseline) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictProxyBaselineGraceDaysRangeRule: StrictProxyBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictProxyBaseline) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictProxyBaselineCodePrefixRule: StrictProxyBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictProxyBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict proxy baseline.
    final class StrictProxyBaselineValidator {
        var rules: [any StrictProxyBaselineRule]

        init(rules: [any StrictProxyBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictProxyBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictProxyBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictProxyBaseline]) -> [String: [String]] {
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

    static func defaultStrictProxyBaselineValidator() -> StrictProxyBaselineValidator {
        return StrictProxyBaselineValidator(
            rules: [
                StrictProxyBaselineTitleLengthRule(maxLength: 86400),
                StrictProxyBaselineArchivedGuardRule(limit: 3600),
                StrictProxyBaselineRequiredTitleRule(message: "strict proxy baseline needs a value"),
                StrictProxyBaselineRequiredContactEmailRule(message: "strict proxy baseline needs a value"),
                StrictProxyBaselineGraceDaysRangeRule(min: 255, max: 86400),
                StrictProxyBaselineCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
