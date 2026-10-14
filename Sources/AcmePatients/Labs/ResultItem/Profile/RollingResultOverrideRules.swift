import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling result override must pass. Check returns its problems, or none.
    protocol RollingResultOverrideRule {
        func check(_ item: RollingResultOverride) -> [String]
    }

    final class RollingResultOverrideTimezoneLengthRule: RollingResultOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingResultOverride) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingResultOverrideCodePrefixRule: RollingResultOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingResultOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingResultOverrideScoreRangeRule: RollingResultOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingResultOverride) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling result override.
    final class RollingResultOverrideValidator {
        var rules: [any RollingResultOverrideRule]

        init(rules: [any RollingResultOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingResultOverride) -> [String] {
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

        func requireValid(_ item: RollingResultOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingResultOverride]) -> [String: [String]] {
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

    static func defaultRollingResultOverrideValidator() -> RollingResultOverrideValidator {
        return RollingResultOverrideValidator(
            rules: [
                RollingResultOverrideTimezoneLengthRule(maxLength: 120),
                RollingResultOverrideCodePrefixRule(prefix: "ACM"),
                RollingResultOverrideScoreRangeRule(min: 2.9, max: 2029.7),
            ]
        )
    }
}
