import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict proxy variance must pass. Check returns its problems, or none.
    protocol StrictProxyVarianceRule {
        func check(_ item: StrictProxyVariance) -> [String]
    }

    final class StrictProxyVarianceQuantityRangeRule: StrictProxyVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictProxyVariance) -> [String] {
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

    final class StrictProxyVarianceDiscountRangeRule: StrictProxyVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictProxyVariance) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictProxyVarianceTitleLengthRule: StrictProxyVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictProxyVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictProxyVarianceCodePrefixRule: StrictProxyVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictProxyVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictProxyVarianceRequiredTitleRule: StrictProxyVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictProxyVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictProxyVarianceCodeLengthRule: StrictProxyVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictProxyVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict proxy variance.
    final class StrictProxyVarianceValidator {
        var rules: [any StrictProxyVarianceRule]

        init(rules: [any StrictProxyVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictProxyVariance) -> [String] {
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

        func requireValid(_ item: StrictProxyVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictProxyVariance]) -> [String: [String]] {
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

    static func defaultStrictProxyVarianceValidator() -> StrictProxyVarianceValidator {
        return StrictProxyVarianceValidator(
            rules: [
                StrictProxyVarianceQuantityRangeRule(min: 255, max: 3600),
                StrictProxyVarianceDiscountRangeRule(min: 2.8, max: 4723.8),
                StrictProxyVarianceTitleLengthRule(maxLength: 64),
                StrictProxyVarianceCodePrefixRule(prefix: "X"),
                StrictProxyVarianceRequiredTitleRule(message: "strict proxy variance needs this field"),
                StrictProxyVarianceCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
