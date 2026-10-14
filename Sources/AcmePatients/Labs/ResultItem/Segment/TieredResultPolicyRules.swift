import AcmePlatform
import Foundation

extension Labs {
    /// A rule a tiered result policy must pass. Check returns its problems, or none.
    protocol TieredResultPolicyRule {
        func check(_ item: TieredResultPolicy) -> [String]
    }

    final class TieredResultPolicyCodeLengthRule: TieredResultPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredResultPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredResultPolicyRequiredSourceRule: TieredResultPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredResultPolicy) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredResultPolicySourceLengthRule: TieredResultPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredResultPolicy) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredResultPolicyVisibleGuardRule: TieredResultPolicyRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredResultPolicy) -> [String] {
            if item.visible && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class TieredResultPolicyCeilingRangeRule: TieredResultPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredResultPolicy) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredResultPolicyRequiredCodeRule: TieredResultPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredResultPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered result policy.
    final class TieredResultPolicyValidator {
        var rules: [any TieredResultPolicyRule]

        init(rules: [any TieredResultPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredResultPolicy) -> [String] {
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

        func requireValid(_ item: TieredResultPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredResultPolicy]) -> [String: [String]] {
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

    static func defaultTieredResultPolicyValidator() -> TieredResultPolicyValidator {
        return TieredResultPolicyValidator(
            rules: [
                TieredResultPolicyCodeLengthRule(maxLength: 16),
                TieredResultPolicyRequiredSourceRule(message: "tiered result policy needs an entry"),
                TieredResultPolicySourceLengthRule(maxLength: 80),
                TieredResultPolicyVisibleGuardRule(limit: 80),
                TieredResultPolicyCeilingRangeRule(min: 4.9, max: 648.4),
                TieredResultPolicyRequiredCodeRule(message: "tiered result policy needs this field"),
            ]
        )
    }
}
