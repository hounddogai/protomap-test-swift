import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result summary must pass. Check returns its problems, or none.
    protocol ResultSummaryRule {
        func check(_ item: ResultSummary) -> [String]
    }

    final class ResultSummaryRateRangeRule: ResultSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultSummary) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ResultSummaryLabelLengthRule: ResultSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultSummaryRequiredSourceRule: ResultSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultSummary) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultSummarySourceLengthRule: ResultSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultSummary) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultSummaryCodePrefixRule: ResultSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ResultSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ResultSummaryRequiredCodeRule: ResultSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a result summary.
    final class ResultSummaryValidator {
        var rules: [any ResultSummaryRule]

        init(rules: [any ResultSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultSummary]) -> [String: [String]] {
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

    static func defaultResultSummaryValidator() -> ResultSummaryValidator {
        return ResultSummaryValidator(
            rules: [
                ResultSummaryRateRangeRule(min: 1.0, max: 3374.5),
                ResultSummaryLabelLengthRule(maxLength: 120),
                ResultSummaryRequiredSourceRule(message: "result summary needs this field"),
                ResultSummarySourceLengthRule(maxLength: 80),
                ResultSummaryCodePrefixRule(prefix: "ACM"),
                ResultSummaryRequiredCodeRule(message: "result summary needs an entry"),
            ]
        )
    }
}
