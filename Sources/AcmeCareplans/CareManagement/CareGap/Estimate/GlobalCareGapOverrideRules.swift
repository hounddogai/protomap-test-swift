import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global care gap override must pass. Check returns its problems, or none.
    protocol GlobalCareGapOverrideRule {
        func check(_ item: GlobalCareGapOverride) -> [String]
    }

    final class GlobalCareGapOverrideRequiredLocaleRule: GlobalCareGapOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCareGapOverride) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCareGapOverrideRequiredCodeRule: GlobalCareGapOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCareGapOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCareGapOverrideAllowedCodeRule: GlobalCareGapOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalCareGapOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class GlobalCareGapOverrideCodeLengthRule: GlobalCareGapOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCareGapOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCareGapOverrideCostRangeRule: GlobalCareGapOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCareGapOverride) -> [String] {
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

    final class GlobalCareGapOverrideArchivedGuardRule: GlobalCareGapOverrideRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalCareGapOverride) -> [String] {
            if item.archived && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a global care gap override.
    final class GlobalCareGapOverrideValidator {
        var rules: [any GlobalCareGapOverrideRule]

        init(rules: [any GlobalCareGapOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCareGapOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalCareGapOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCareGapOverride]) -> [String: [String]] {
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

    static func defaultGlobalCareGapOverrideValidator() -> GlobalCareGapOverrideValidator {
        return GlobalCareGapOverrideValidator(
            rules: [
                GlobalCareGapOverrideRequiredLocaleRule(message: "global care gap override needs an entry"),
                GlobalCareGapOverrideRequiredCodeRule(message: "global care gap override needs this field"),
                GlobalCareGapOverrideAllowedCodeRule(allowed: ["capped", "primary"]),
                GlobalCareGapOverrideCodeLengthRule(maxLength: 32),
                GlobalCareGapOverrideCostRangeRule(min: 8.3, max: 138.3),
                GlobalCareGapOverrideArchivedGuardRule(limit: 3600),
            ]
        )
    }
}
