import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback credential draft must pass. Check returns its problems, or none.
    protocol FallbackCredentialDraftRule {
        func check(_ item: FallbackCredentialDraft) -> [String]
    }

    final class FallbackCredentialDraftRequiredTimezoneRule: FallbackCredentialDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCredentialDraft) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCredentialDraftNameLengthRule: FallbackCredentialDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCredentialDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCredentialDraftActiveGuardRule: FallbackCredentialDraftRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: FallbackCredentialDraft) -> [String] {
            if item.active && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class FallbackCredentialDraftExpiresAtRangeRule: FallbackCredentialDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCredentialDraft) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback credential draft.
    final class FallbackCredentialDraftValidator {
        var rules: [any FallbackCredentialDraftRule]

        init(rules: [any FallbackCredentialDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCredentialDraft) -> [String] {
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

        func requireValid(_ item: FallbackCredentialDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCredentialDraft]) -> [String: [String]] {
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

    static func defaultFallbackCredentialDraftValidator() -> FallbackCredentialDraftValidator {
        return FallbackCredentialDraftValidator(
            rules: [
                FallbackCredentialDraftRequiredTimezoneRule(message: "fallback credential draft needs a value"),
                FallbackCredentialDraftNameLengthRule(maxLength: 120),
                FallbackCredentialDraftActiveGuardRule(limit: 1000),
                FallbackCredentialDraftExpiresAtRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
