import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional float pool variance must pass. Check returns its problems, or none.
    protocol RegionalFloatPoolVarianceRule {
        func check(_ item: RegionalFloatPoolVariance) -> [String]
    }

    final class RegionalFloatPoolVarianceRateRangeRule: RegionalFloatPoolVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalFloatPoolVariance) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalFloatPoolVarianceCodePrefixRule: RegionalFloatPoolVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalFloatPoolVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalFloatPoolVarianceLimitRangeRule: RegionalFloatPoolVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalFloatPoolVariance) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalFloatPoolVarianceCodeLengthRule: RegionalFloatPoolVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalFloatPoolVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalFloatPoolVarianceAllowedCodeRule: RegionalFloatPoolVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalFloatPoolVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class RegionalFloatPoolVarianceRequiredSummaryRule: RegionalFloatPoolVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalFloatPoolVariance) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional float pool variance.
    final class RegionalFloatPoolVarianceValidator {
        var rules: [any RegionalFloatPoolVarianceRule]

        init(rules: [any RegionalFloatPoolVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalFloatPoolVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalFloatPoolVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalFloatPoolVariance]) -> [String: [String]] {
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

    static func defaultRegionalFloatPoolVarianceValidator() -> RegionalFloatPoolVarianceValidator {
        return RegionalFloatPoolVarianceValidator(
            rules: [
                RegionalFloatPoolVarianceRateRangeRule(min: 8.7, max: 1379.5),
                RegionalFloatPoolVarianceCodePrefixRule(prefix: "Q"),
                RegionalFloatPoolVarianceLimitRangeRule(min: 1000, max: 1000),
                RegionalFloatPoolVarianceCodeLengthRule(maxLength: 1000),
                RegionalFloatPoolVarianceAllowedCodeRule(allowed: ["lenient", "adaptive", "manual"]),
                RegionalFloatPoolVarianceRequiredSummaryRule(message: "regional float pool variance needs a value"),
            ]
        )
    }
}
