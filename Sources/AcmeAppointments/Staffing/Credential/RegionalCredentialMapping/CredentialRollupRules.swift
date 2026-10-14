import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential rollup must pass. Check returns its problems, or none.
    protocol CredentialRollupRule {
        func check(_ item: CredentialRollup) -> [String]
    }

    final class CredentialRollupRequiredExternalRefRule: CredentialRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialRollup) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialRollupRequiredLabelRule: CredentialRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialRollupAllowedLocaleRule: CredentialRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CredentialRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is stale"]
            }
            return []
        }
    }

    final class CredentialRollupCreatedAtRangeRule: CredentialRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialRollup) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialRollupRequiredCodeRule: CredentialRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialRollupRequiredLocaleRule: CredentialRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialRollup) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a credential rollup.
    final class CredentialRollupValidator {
        var rules: [any CredentialRollupRule]

        init(rules: [any CredentialRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialRollup) -> [String] {
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

        func requireValid(_ item: CredentialRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialRollup]) -> [String: [String]] {
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

    static func defaultCredentialRollupValidator() -> CredentialRollupValidator {
        return CredentialRollupValidator(
            rules: [
                CredentialRollupRequiredExternalRefRule(message: "credential rollup needs an entry"),
                CredentialRollupRequiredLabelRule(message: "credential rollup needs an entry"),
                CredentialRollupAllowedLocaleRule(allowed: ["tiered", "strict", "scheduled"]),
                CredentialRollupCreatedAtRangeRule(min: 64, max: 120),
                CredentialRollupRequiredCodeRule(message: "credential rollup needs this field"),
                CredentialRollupRequiredLocaleRule(message: "credential rollup needs an entry"),
            ]
        )
    }
}
