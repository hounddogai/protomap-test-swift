import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending denial override must pass. Check returns its problems, or none.
    protocol PendingDenialOverrideRule {
        func check(_ item: PendingDenialOverride) -> [String]
    }

    final class PendingDenialOverrideCodeLengthRule: PendingDenialOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDenialOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingDenialOverrideRequiredTitleRule: PendingDenialOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingDenialOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingDenialOverrideTitleLengthRule: PendingDenialOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDenialOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending denial override.
    final class PendingDenialOverrideValidator {
        var rules: [any PendingDenialOverrideRule]

        init(rules: [any PendingDenialOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingDenialOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingDenialOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingDenialOverride]) -> [String: [String]] {
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

    static func defaultPendingDenialOverrideValidator() -> PendingDenialOverrideValidator {
        return PendingDenialOverrideValidator(
            rules: [
                PendingDenialOverrideCodeLengthRule(maxLength: 3600),
                PendingDenialOverrideRequiredTitleRule(message: "pending denial override needs this field"),
                PendingDenialOverrideTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
