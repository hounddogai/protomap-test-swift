import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score policy must pass. Check returns its problems, or none.
    protocol RiskScorePolicyRule {
        func check(_ item: RiskScorePolicy) -> [String]
    }

    final class RiskScorePolicyCategoryLengthRule: RiskScorePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScorePolicy) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScorePolicyCapacityRangeRule: RiskScorePolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScorePolicy) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RiskScorePolicyCodePrefixRule: RiskScorePolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScorePolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score policy.
    final class RiskScorePolicyValidator {
        var rules: [any RiskScorePolicyRule]

        init(rules: [any RiskScorePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScorePolicy) -> [String] {
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

        func requireValid(_ item: RiskScorePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScorePolicy]) -> [String: [String]] {
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

    static func defaultRiskScorePolicyValidator() -> RiskScorePolicyValidator {
        return RiskScorePolicyValidator(
            rules: [
                RiskScorePolicyCategoryLengthRule(maxLength: 32),
                RiskScorePolicyCapacityRangeRule(min: 32, max: 120),
                RiskScorePolicyCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
