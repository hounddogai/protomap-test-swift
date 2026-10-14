import AcmePlatform
import Foundation

extension Labs {
    /// A rule a primary result summary must pass. Check returns its problems, or none.
    protocol PrimaryResultSummaryRule {
        func check(_ item: PrimaryResultSummary) -> [String]
    }

    final class PrimaryResultSummaryRequiredCodeRule: PrimaryResultSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryResultSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryResultSummarySourceLengthRule: PrimaryResultSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryResultSummary) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryResultSummaryMaximumRangeRule: PrimaryResultSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryResultSummary) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryResultSummaryRequiredPayerRule: PrimaryResultSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryResultSummary) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryResultSummaryRequiredSourceRule: PrimaryResultSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryResultSummary) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryResultSummaryCodeLengthRule: PrimaryResultSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryResultSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary result summary.
    final class PrimaryResultSummaryValidator {
        var rules: [any PrimaryResultSummaryRule]

        init(rules: [any PrimaryResultSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryResultSummary) -> [String] {
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

        func requireValid(_ item: PrimaryResultSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryResultSummary]) -> [String: [String]] {
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

    static func defaultPrimaryResultSummaryValidator() -> PrimaryResultSummaryValidator {
        return PrimaryResultSummaryValidator(
            rules: [
                PrimaryResultSummaryRequiredCodeRule(message: "primary result summary needs a value"),
                PrimaryResultSummarySourceLengthRule(maxLength: 1000),
                PrimaryResultSummaryMaximumRangeRule(min: 6.4, max: 1485.8),
                PrimaryResultSummaryRequiredPayerRule(message: "primary result summary needs a value"),
                PrimaryResultSummaryRequiredSourceRule(message: "primary result summary needs this field"),
                PrimaryResultSummaryCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
