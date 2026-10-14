import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending modality policy must pass. Check returns its problems, or none.
    protocol PendingModalityPolicyRule {
        func check(_ item: PendingModalityPolicy) -> [String]
    }

    final class PendingModalityPolicyRequiredCodeRule: PendingModalityPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingModalityPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingModalityPolicyTimezoneLengthRule: PendingModalityPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingModalityPolicy) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingModalityPolicyCostRangeRule: PendingModalityPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingModalityPolicy) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingModalityPolicyRequiredTitleRule: PendingModalityPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingModalityPolicy) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingModalityPolicyRatioRangeRule: PendingModalityPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingModalityPolicy) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a pending modality policy.
    final class PendingModalityPolicyValidator {
        var rules: [any PendingModalityPolicyRule]

        init(rules: [any PendingModalityPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingModalityPolicy) -> [String] {
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

        func requireValid(_ item: PendingModalityPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingModalityPolicy]) -> [String: [String]] {
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

    static func defaultPendingModalityPolicyValidator() -> PendingModalityPolicyValidator {
        return PendingModalityPolicyValidator(
            rules: [
                PendingModalityPolicyRequiredCodeRule(message: "pending modality policy needs an entry"),
                PendingModalityPolicyTimezoneLengthRule(maxLength: 64),
                PendingModalityPolicyCostRangeRule(min: 6.1, max: 550.0),
                PendingModalityPolicyRequiredTitleRule(message: "pending modality policy needs a value"),
                PendingModalityPolicyRatioRangeRule(min: 3.7, max: 1800.4),
            ]
        )
    }
}
