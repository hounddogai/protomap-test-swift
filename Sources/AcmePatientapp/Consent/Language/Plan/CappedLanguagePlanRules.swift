import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped language plan must pass. Check returns its problems, or none.
    protocol CappedLanguagePlanRule {
        func check(_ item: CappedLanguagePlan) -> [String]
    }

    final class CappedLanguagePlanMaximumRangeRule: CappedLanguagePlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedLanguagePlan) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedLanguagePlanRequiredCodeRule: CappedLanguagePlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedLanguagePlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedLanguagePlanPinnedGuardRule: CappedLanguagePlanRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CappedLanguagePlan) -> [String] {
            if item.pinned && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class CappedLanguagePlanRequiredReviewerRule: CappedLanguagePlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedLanguagePlan) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedLanguagePlanCodeLengthRule: CappedLanguagePlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedLanguagePlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedLanguagePlanAllowedNameRule: CappedLanguagePlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedLanguagePlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a capped language plan.
    final class CappedLanguagePlanValidator {
        var rules: [any CappedLanguagePlanRule]

        init(rules: [any CappedLanguagePlanRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedLanguagePlan) -> [String] {
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

        func requireValid(_ item: CappedLanguagePlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedLanguagePlan]) -> [String: [String]] {
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

    static func defaultCappedLanguagePlanValidator() -> CappedLanguagePlanValidator {
        return CappedLanguagePlanValidator(
            rules: [
                CappedLanguagePlanMaximumRangeRule(min: 4.3, max: 1997.9),
                CappedLanguagePlanRequiredCodeRule(message: "capped language plan needs an entry"),
                CappedLanguagePlanPinnedGuardRule(limit: 3.7),
                CappedLanguagePlanRequiredReviewerRule(message: "capped language plan needs an entry"),
                CappedLanguagePlanCodeLengthRule(maxLength: 16),
                CappedLanguagePlanAllowedNameRule(allowed: ["weighted"]),
            ]
        )
    }
}
