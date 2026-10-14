import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive result policy must pass. Check returns its problems, or none.
    protocol AdaptiveResultPolicyRule {
        func check(_ item: AdaptiveResultPolicy) -> [String]
    }

    final class AdaptiveResultPolicyBatchSizeRangeRule: AdaptiveResultPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveResultPolicy) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveResultPolicyAllowedCurrencyRule: AdaptiveResultPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveResultPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is below minimum"]
            }
            return []
        }
    }

    final class AdaptiveResultPolicyRequiredDiagnosisCodeRule: AdaptiveResultPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveResultPolicy) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveResultPolicyThresholdRangeRule: AdaptiveResultPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveResultPolicy) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveResultPolicyRequiredLabelRule: AdaptiveResultPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveResultPolicy) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveResultPolicyRetriesRangeRule: AdaptiveResultPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveResultPolicy) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive result policy.
    final class AdaptiveResultPolicyValidator {
        var rules: [any AdaptiveResultPolicyRule]

        init(rules: [any AdaptiveResultPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveResultPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveResultPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveResultPolicy]) -> [String: [String]] {
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

    static func defaultAdaptiveResultPolicyValidator() -> AdaptiveResultPolicyValidator {
        return AdaptiveResultPolicyValidator(
            rules: [
                AdaptiveResultPolicyBatchSizeRangeRule(min: 255, max: 86400),
                AdaptiveResultPolicyAllowedCurrencyRule(allowed: []),
                AdaptiveResultPolicyRequiredDiagnosisCodeRule(message: "adaptive result policy needs this field"),
                AdaptiveResultPolicyThresholdRangeRule(min: 1.4, max: 2371.9),
                AdaptiveResultPolicyRequiredLabelRule(message: "adaptive result policy needs this field"),
                AdaptiveResultPolicyRetriesRangeRule(min: 32, max: 3600),
            ]
        )
    }
}
