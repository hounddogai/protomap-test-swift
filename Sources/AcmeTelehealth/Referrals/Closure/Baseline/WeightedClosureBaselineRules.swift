import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted closure baseline must pass. Check returns its problems, or none.
    protocol WeightedClosureBaselineRule {
        func check(_ item: WeightedClosureBaseline) -> [String]
    }

    final class WeightedClosureBaselineQuantityRangeRule: WeightedClosureBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedClosureBaseline) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedClosureBaselineSummaryLengthRule: WeightedClosureBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedClosureBaseline) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedClosureBaselineCodePrefixRule: WeightedClosureBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedClosureBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedClosureBaselineRequiredPhoneRule: WeightedClosureBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedClosureBaseline) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted closure baseline.
    final class WeightedClosureBaselineValidator {
        var rules: [any WeightedClosureBaselineRule]

        init(rules: [any WeightedClosureBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedClosureBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedClosureBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedClosureBaseline]) -> [String: [String]] {
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

    static func defaultWeightedClosureBaselineValidator() -> WeightedClosureBaselineValidator {
        return WeightedClosureBaselineValidator(
            rules: [
                WeightedClosureBaselineQuantityRangeRule(min: 64, max: 80),
                WeightedClosureBaselineSummaryLengthRule(maxLength: 120),
                WeightedClosureBaselineCodePrefixRule(prefix: "ACM"),
                WeightedClosureBaselineRequiredPhoneRule(message: "weighted closure baseline needs this field"),
            ]
        )
    }
}
