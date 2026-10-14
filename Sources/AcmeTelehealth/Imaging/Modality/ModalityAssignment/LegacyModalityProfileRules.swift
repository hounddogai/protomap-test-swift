import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy modality profile must pass. Check returns its problems, or none.
    protocol LegacyModalityProfileRule {
        func check(_ item: LegacyModalityProfile) -> [String]
    }

    final class LegacyModalityProfileCodePrefixRule: LegacyModalityProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyModalityProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyModalityProfileSpecialtyLengthRule: LegacyModalityProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyModalityProfile) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyModalityProfileRequiredCodeRule: LegacyModalityProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyModalityProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyModalityProfileAllowedExternalRefRule: LegacyModalityProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyModalityProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy modality profile.
    final class LegacyModalityProfileValidator {
        var rules: [any LegacyModalityProfileRule]

        init(rules: [any LegacyModalityProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyModalityProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyModalityProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyModalityProfile]) -> [String: [String]] {
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

    static func defaultLegacyModalityProfileValidator() -> LegacyModalityProfileValidator {
        return LegacyModalityProfileValidator(
            rules: [
                LegacyModalityProfileCodePrefixRule(prefix: "Q"),
                LegacyModalityProfileSpecialtyLengthRule(maxLength: 86400),
                LegacyModalityProfileRequiredCodeRule(message: "legacy modality profile needs a value"),
                LegacyModalityProfileAllowedExternalRefRule(allowed: []),
            ]
        )
    }
}
