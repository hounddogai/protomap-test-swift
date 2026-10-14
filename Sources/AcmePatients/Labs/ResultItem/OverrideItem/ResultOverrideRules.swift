import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result override must pass. Check returns its problems, or none.
    protocol ResultOverrideRule {
        func check(_ item: ResultOverride) -> [String]
    }

    final class ResultOverrideCeilingRangeRule: ResultOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultOverride) -> [String] {
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

    final class ResultOverrideCodePrefixRule: ResultOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ResultOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ResultOverrideExternalRefLengthRule: ResultOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultOverride) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultOverrideEndsAtRangeRule: ResultOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultOverride) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ResultOverrideCodeLengthRule: ResultOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a result override.
    final class ResultOverrideValidator {
        var rules: [any ResultOverrideRule]

        init(rules: [any ResultOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultOverride]) -> [String: [String]] {
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

    static func defaultResultOverrideValidator() -> ResultOverrideValidator {
        return ResultOverrideValidator(
            rules: [
                ResultOverrideCeilingRangeRule(min: 4.0, max: 1680.0),
                ResultOverrideCodePrefixRule(prefix: "OPS"),
                ResultOverrideExternalRefLengthRule(maxLength: 3600),
                ResultOverrideEndsAtRangeRule(min: 80, max: 3600),
                ResultOverrideCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
