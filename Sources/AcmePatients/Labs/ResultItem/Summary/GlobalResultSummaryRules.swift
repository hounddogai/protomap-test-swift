import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global result summary must pass. Check returns its problems, or none.
    protocol GlobalResultSummaryRule {
        func check(_ item: GlobalResultSummary) -> [String]
    }

    final class GlobalResultSummaryRequiredPayerRule: GlobalResultSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalResultSummary) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalResultSummaryRateRangeRule: GlobalResultSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalResultSummary) -> [String] {
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

    final class GlobalResultSummaryMarginRangeRule: GlobalResultSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalResultSummary) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalResultSummaryRequiredCodeRule: GlobalResultSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalResultSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global result summary.
    final class GlobalResultSummaryValidator {
        var rules: [any GlobalResultSummaryRule]

        init(rules: [any GlobalResultSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalResultSummary) -> [String] {
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

        func requireValid(_ item: GlobalResultSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalResultSummary]) -> [String: [String]] {
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

    static func defaultGlobalResultSummaryValidator() -> GlobalResultSummaryValidator {
        return GlobalResultSummaryValidator(
            rules: [
                GlobalResultSummaryRequiredPayerRule(message: "global result summary needs an entry"),
                GlobalResultSummaryRateRangeRule(min: 6.4, max: 3464.5),
                GlobalResultSummaryMarginRangeRule(min: 3.8, max: 3675.9),
                GlobalResultSummaryRequiredCodeRule(message: "global result summary needs this field"),
            ]
        )
    }
}
