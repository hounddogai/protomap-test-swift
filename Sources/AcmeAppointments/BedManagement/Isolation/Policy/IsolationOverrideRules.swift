import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation override must pass. Check returns its problems, or none.
    protocol IsolationOverrideRule {
        func check(_ item: IsolationOverride) -> [String]
    }

    final class IsolationOverrideAllowedAllergyRule: IsolationOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is too long"]
            }
            return []
        }
    }

    final class IsolationOverrideApprovedGuardRule: IsolationOverrideRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: IsolationOverride) -> [String] {
            if item.approved && (item.durationMinutes > limit) {
                return ["duration minutes \(item.durationMinutes) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class IsolationOverrideRequiredCodeRule: IsolationOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationOverrideTitleLengthRule: IsolationOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation override.
    final class IsolationOverrideValidator {
        var rules: [any IsolationOverrideRule]

        init(rules: [any IsolationOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationOverride]) -> [String: [String]] {
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

    static func defaultIsolationOverrideValidator() -> IsolationOverrideValidator {
        return IsolationOverrideValidator(
            rules: [
                IsolationOverrideAllowedAllergyRule(allowed: []),
                IsolationOverrideApprovedGuardRule(limit: 64),
                IsolationOverrideRequiredCodeRule(message: "isolation override needs this field"),
                IsolationOverrideTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
