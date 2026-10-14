import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility policy must pass. Check returns its problems, or none.
    protocol EligibilityPolicyRule {
        func check(_ item: EligibilityPolicy) -> [String]
    }

    final class EligibilityPolicyThresholdRangeRule: EligibilityPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityPolicy) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class EligibilityPolicyRequiredNameRule: EligibilityPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityPolicyOwnerIDLengthRule: EligibilityPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityPolicy) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityPolicyCodeLengthRule: EligibilityPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityPolicyRequiredCodeRule: EligibilityPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityPolicyNameLengthRule: EligibilityPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityPolicy) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility policy.
    final class EligibilityPolicyValidator {
        var rules: [any EligibilityPolicyRule]

        init(rules: [any EligibilityPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityPolicy]) -> [String: [String]] {
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

    static func defaultEligibilityPolicyValidator() -> EligibilityPolicyValidator {
        return EligibilityPolicyValidator(
            rules: [
                EligibilityPolicyThresholdRangeRule(min: 8.3, max: 3647.5),
                EligibilityPolicyRequiredNameRule(message: "eligibility policy needs this field"),
                EligibilityPolicyOwnerIDLengthRule(maxLength: 32),
                EligibilityPolicyCodeLengthRule(maxLength: 255),
                EligibilityPolicyRequiredCodeRule(message: "eligibility policy needs a value"),
                EligibilityPolicyNameLengthRule(maxLength: 80),
            ]
        )
    }
}
