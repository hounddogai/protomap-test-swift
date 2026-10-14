import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility draft must pass. Check returns its problems, or none.
    protocol EligibilityDraftRule {
        func check(_ item: EligibilityDraft) -> [String]
    }

    final class EligibilityDraftCodePrefixRule: EligibilityDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class EligibilityDraftActiveGuardRule: EligibilityDraftRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: EligibilityDraft) -> [String] {
            if item.active && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class EligibilityDraftAllowedCategoryRule: EligibilityDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is stale"]
            }
            return []
        }
    }

    final class EligibilityDraftVersionRangeRule: EligibilityDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityDraft) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility draft.
    final class EligibilityDraftValidator {
        var rules: [any EligibilityDraftRule]

        init(rules: [any EligibilityDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityDraft]) -> [String: [String]] {
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

    static func defaultEligibilityDraftValidator() -> EligibilityDraftValidator {
        return EligibilityDraftValidator(
            rules: [
                EligibilityDraftCodePrefixRule(prefix: "Q"),
                EligibilityDraftActiveGuardRule(limit: 3600),
                EligibilityDraftAllowedCategoryRule(allowed: ["weighted", "legacy", "legacy"]),
                EligibilityDraftVersionRangeRule(min: 64, max: 80),
            ]
        )
    }
}
