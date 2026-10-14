import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted risk score policy must pass. Check returns its problems, or none.
    protocol WeightedRiskScorePolicyRule {
        func check(_ item: WeightedRiskScorePolicy) -> [String]
    }

    final class WeightedRiskScorePolicyLabelLengthRule: WeightedRiskScorePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRiskScorePolicy) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRiskScorePolicyRequiredLabelRule: WeightedRiskScorePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRiskScorePolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRiskScorePolicyCodePrefixRule: WeightedRiskScorePolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedRiskScorePolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted risk score policy.
    final class WeightedRiskScorePolicyValidator {
        var rules: [any WeightedRiskScorePolicyRule]

        init(rules: [any WeightedRiskScorePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRiskScorePolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedRiskScorePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRiskScorePolicy]) -> [String: [String]] {
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

    static func defaultWeightedRiskScorePolicyValidator() -> WeightedRiskScorePolicyValidator {
        return WeightedRiskScorePolicyValidator(
            rules: [
                WeightedRiskScorePolicyLabelLengthRule(maxLength: 86400),
                WeightedRiskScorePolicyRequiredLabelRule(message: "weighted risk score policy needs an entry"),
                WeightedRiskScorePolicyCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
