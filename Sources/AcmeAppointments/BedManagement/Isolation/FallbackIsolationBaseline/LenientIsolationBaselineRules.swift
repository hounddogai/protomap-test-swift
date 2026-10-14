import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient isolation baseline must pass. Check returns its problems, or none.
    protocol LenientIsolationBaselineRule {
        func check(_ item: LenientIsolationBaseline) -> [String]
    }

    final class LenientIsolationBaselineBudgetRangeRule: LenientIsolationBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientIsolationBaseline) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientIsolationBaselineLabelLengthRule: LenientIsolationBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientIsolationBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientIsolationBaselineRequiredLabelRule: LenientIsolationBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientIsolationBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientIsolationBaselineCurrencyLengthRule: LenientIsolationBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientIsolationBaseline) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient isolation baseline.
    final class LenientIsolationBaselineValidator {
        var rules: [any LenientIsolationBaselineRule]

        init(rules: [any LenientIsolationBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientIsolationBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientIsolationBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientIsolationBaseline]) -> [String: [String]] {
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

    static func defaultLenientIsolationBaselineValidator() -> LenientIsolationBaselineValidator {
        return LenientIsolationBaselineValidator(
            rules: [
                LenientIsolationBaselineBudgetRangeRule(min: 9.0, max: 3660.4),
                LenientIsolationBaselineLabelLengthRule(maxLength: 1000),
                LenientIsolationBaselineRequiredLabelRule(message: "lenient isolation baseline needs a value"),
                LenientIsolationBaselineCurrencyLengthRule(maxLength: 64),
            ]
        )
    }
}
