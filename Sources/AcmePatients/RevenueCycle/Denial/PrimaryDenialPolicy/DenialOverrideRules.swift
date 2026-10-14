import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial override must pass. Check returns its problems, or none.
    protocol DenialOverrideRule {
        func check(_ item: DenialOverride) -> [String]
    }

    final class DenialOverrideCodePrefixRule: DenialOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DenialOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DenialOverrideRequiredSegmentRule: DenialOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialOverride) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialOverrideRequiredTitleRule: DenialOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a denial override.
    final class DenialOverrideValidator {
        var rules: [any DenialOverrideRule]

        init(rules: [any DenialOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialOverride]) -> [String: [String]] {
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

    static func defaultDenialOverrideValidator() -> DenialOverrideValidator {
        return DenialOverrideValidator(
            rules: [
                DenialOverrideCodePrefixRule(prefix: "X"),
                DenialOverrideRequiredSegmentRule(message: "denial override needs this field"),
                DenialOverrideRequiredTitleRule(message: "denial override needs an entry"),
            ]
        )
    }
}
