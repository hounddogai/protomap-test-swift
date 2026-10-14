import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure override must pass. Check returns its problems, or none.
    protocol ClosureOverrideRule {
        func check(_ item: ClosureOverride) -> [String]
    }

    final class ClosureOverrideAllowedDiagnosisCodeRule: ClosureOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClosureOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is too long"]
            }
            return []
        }
    }

    final class ClosureOverrideRequiredCodeRule: ClosureOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureOverrideCodePrefixRule: ClosureOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClosureOverrideDiagnosisCodeLengthRule: ClosureOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureOverride) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure override.
    final class ClosureOverrideValidator {
        var rules: [any ClosureOverrideRule]

        init(rules: [any ClosureOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureOverride) -> [String] {
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

        func requireValid(_ item: ClosureOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureOverride]) -> [String: [String]] {
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

    static func defaultClosureOverrideValidator() -> ClosureOverrideValidator {
        return ClosureOverrideValidator(
            rules: [
                ClosureOverrideAllowedDiagnosisCodeRule(allowed: ["legacy", "legacy", "adaptive"]),
                ClosureOverrideRequiredCodeRule(message: "closure override needs this field"),
                ClosureOverrideCodePrefixRule(prefix: "OPS"),
                ClosureOverrideDiagnosisCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
