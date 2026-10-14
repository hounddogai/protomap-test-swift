import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional study rollup must pass. Check returns its problems, or none.
    protocol RegionalStudyRollupRule {
        func check(_ item: RegionalStudyRollup) -> [String]
    }

    final class RegionalStudyRollupTimezoneLengthRule: RegionalStudyRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalStudyRollup) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalStudyRollupAllowedTimezoneRule: RegionalStudyRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalStudyRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is expired"]
            }
            return []
        }
    }

    final class RegionalStudyRollupCodeLengthRule: RegionalStudyRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalStudyRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalStudyRollupCodePrefixRule: RegionalStudyRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalStudyRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalStudyRollupCeilingRangeRule: RegionalStudyRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalStudyRollup) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a regional study rollup.
    final class RegionalStudyRollupValidator {
        var rules: [any RegionalStudyRollupRule]

        init(rules: [any RegionalStudyRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalStudyRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalStudyRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalStudyRollup]) -> [String: [String]] {
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

    static func defaultRegionalStudyRollupValidator() -> RegionalStudyRollupValidator {
        return RegionalStudyRollupValidator(
            rules: [
                RegionalStudyRollupTimezoneLengthRule(maxLength: 120),
                RegionalStudyRollupAllowedTimezoneRule(allowed: ["rolling", "manual"]),
                RegionalStudyRollupCodeLengthRule(maxLength: 16),
                RegionalStudyRollupCodePrefixRule(prefix: "REF"),
                RegionalStudyRollupCeilingRangeRule(min: 6.5, max: 3870.0),
            ]
        )
    }
}
