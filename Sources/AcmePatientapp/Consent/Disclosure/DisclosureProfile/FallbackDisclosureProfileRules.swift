import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback disclosure profile must pass. Check returns its problems, or none.
    protocol FallbackDisclosureProfileRule {
        func check(_ item: FallbackDisclosureProfile) -> [String]
    }

    final class FallbackDisclosureProfileCodePrefixRule: FallbackDisclosureProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackDisclosureProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackDisclosureProfileAllowedCodeRule: FallbackDisclosureProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackDisclosureProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class FallbackDisclosureProfileCodeLengthRule: FallbackDisclosureProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDisclosureProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback disclosure profile.
    final class FallbackDisclosureProfileValidator {
        var rules: [any FallbackDisclosureProfileRule]

        init(rules: [any FallbackDisclosureProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDisclosureProfile) -> [String] {
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

        func requireValid(_ item: FallbackDisclosureProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDisclosureProfile]) -> [String: [String]] {
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

    static func defaultFallbackDisclosureProfileValidator() -> FallbackDisclosureProfileValidator {
        return FallbackDisclosureProfileValidator(
            rules: [
                FallbackDisclosureProfileCodePrefixRule(prefix: "X"),
                FallbackDisclosureProfileAllowedCodeRule(allowed: []),
                FallbackDisclosureProfileCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
