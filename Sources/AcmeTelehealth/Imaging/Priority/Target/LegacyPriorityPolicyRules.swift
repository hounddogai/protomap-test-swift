import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy priority policy must pass. Check returns its problems, or none.
    protocol LegacyPriorityPolicyRule {
        func check(_ item: LegacyPriorityPolicy) -> [String]
    }

    final class LegacyPriorityPolicyTitleLengthRule: LegacyPriorityPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyPriorityPolicy) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyPriorityPolicyCodePrefixRule: LegacyPriorityPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyPriorityPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyPriorityPolicyDosageMgRangeRule: LegacyPriorityPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyPriorityPolicy) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyPriorityPolicyRequiredAllergyRule: LegacyPriorityPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyPriorityPolicy) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy priority policy.
    final class LegacyPriorityPolicyValidator {
        var rules: [any LegacyPriorityPolicyRule]

        init(rules: [any LegacyPriorityPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyPriorityPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyPriorityPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyPriorityPolicy]) -> [String: [String]] {
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

    static func defaultLegacyPriorityPolicyValidator() -> LegacyPriorityPolicyValidator {
        return LegacyPriorityPolicyValidator(
            rules: [
                LegacyPriorityPolicyTitleLengthRule(maxLength: 16),
                LegacyPriorityPolicyCodePrefixRule(prefix: "REF"),
                LegacyPriorityPolicyDosageMgRangeRule(min: 8.3, max: 4348.3),
                LegacyPriorityPolicyRequiredAllergyRule(message: "legacy priority policy needs this field"),
            ]
        )
    }
}
