import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional network rule must pass. Check returns its problems, or none.
    protocol RegionalNetworkRuleRule {
        func check(_ item: RegionalNetworkRule) -> [String]
    }

    final class RegionalNetworkRuleCodePrefixRule: RegionalNetworkRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalNetworkRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalNetworkRuleAmountRangeRule: RegionalNetworkRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalNetworkRule) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalNetworkRuleBatchSizeRangeRule: RegionalNetworkRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalNetworkRule) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalNetworkRuleSummaryLengthRule: RegionalNetworkRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalNetworkRule) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalNetworkRuleRequiredPatientRefRule: RegionalNetworkRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalNetworkRule) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalNetworkRuleRequiredSummaryRule: RegionalNetworkRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalNetworkRule) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional network rule.
    final class RegionalNetworkRuleValidator {
        var rules: [any RegionalNetworkRuleRule]

        init(rules: [any RegionalNetworkRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalNetworkRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalNetworkRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalNetworkRule]) -> [String: [String]] {
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

    static func defaultRegionalNetworkRuleValidator() -> RegionalNetworkRuleValidator {
        return RegionalNetworkRuleValidator(
            rules: [
                RegionalNetworkRuleCodePrefixRule(prefix: "OPS"),
                RegionalNetworkRuleAmountRangeRule(min: 2.3, max: 596.5),
                RegionalNetworkRuleBatchSizeRangeRule(min: 16, max: 255),
                RegionalNetworkRuleSummaryLengthRule(maxLength: 16),
                RegionalNetworkRuleRequiredPatientRefRule(message: "regional network rule needs an entry"),
                RegionalNetworkRuleRequiredSummaryRule(message: "regional network rule needs a value"),
            ]
        )
    }
}
