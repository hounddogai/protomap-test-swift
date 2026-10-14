import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default shift score must pass. Check returns its problems, or none.
    protocol DefaultShiftScoreRule {
        func check(_ item: DefaultShiftScore) -> [String]
    }

    final class DefaultShiftScoreRequiredSourceRule: DefaultShiftScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultShiftScore) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultShiftScoreCodePrefixRule: DefaultShiftScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultShiftScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultShiftScoreNameLengthRule: DefaultShiftScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultShiftScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultShiftScoreRateRangeRule: DefaultShiftScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultShiftScore) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultShiftScoreRequiredNameRule: DefaultShiftScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultShiftScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default shift score.
    final class DefaultShiftScoreValidator {
        var rules: [any DefaultShiftScoreRule]

        init(rules: [any DefaultShiftScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultShiftScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultShiftScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultShiftScore]) -> [String: [String]] {
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

    static func defaultDefaultShiftScoreValidator() -> DefaultShiftScoreValidator {
        return DefaultShiftScoreValidator(
            rules: [
                DefaultShiftScoreRequiredSourceRule(message: "default shift score needs a value"),
                DefaultShiftScoreCodePrefixRule(prefix: "Q"),
                DefaultShiftScoreNameLengthRule(maxLength: 16),
                DefaultShiftScoreRateRangeRule(min: 7.5, max: 1034.4),
                DefaultShiftScoreRequiredNameRule(message: "default shift score needs this field"),
            ]
        )
    }
}
