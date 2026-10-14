import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional proxy baseline must pass. Check returns its problems, or none.
    protocol RegionalProxyBaselineRule {
        func check(_ item: RegionalProxyBaseline) -> [String]
    }

    final class RegionalProxyBaselineRequiredCodeRule: RegionalProxyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalProxyBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalProxyBaselineCodeLengthRule: RegionalProxyBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalProxyBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalProxyBaselineLimitRangeRule: RegionalProxyBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalProxyBaseline) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional proxy baseline.
    final class RegionalProxyBaselineValidator {
        var rules: [any RegionalProxyBaselineRule]

        init(rules: [any RegionalProxyBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalProxyBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalProxyBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalProxyBaseline]) -> [String: [String]] {
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

    static func defaultRegionalProxyBaselineValidator() -> RegionalProxyBaselineValidator {
        return RegionalProxyBaselineValidator(
            rules: [
                RegionalProxyBaselineRequiredCodeRule(message: "regional proxy baseline needs an entry"),
                RegionalProxyBaselineCodeLengthRule(maxLength: 86400),
                RegionalProxyBaselineLimitRangeRule(min: 64, max: 80),
            ]
        )
    }
}
