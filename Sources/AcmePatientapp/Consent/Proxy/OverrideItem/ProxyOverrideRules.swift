import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy override must pass. Check returns its problems, or none.
    protocol ProxyOverrideRule {
        func check(_ item: ProxyOverride) -> [String]
    }

    final class ProxyOverrideCodePrefixRule: ProxyOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyOverrideCodeLengthRule: ProxyOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyOverrideApprovedGuardRule: ProxyOverrideRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ProxyOverride) -> [String] {
            if item.approved && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ProxyOverrideExpiresAtRangeRule: ProxyOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyOverride) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProxyOverrideRequiredCodeRule: ProxyOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy override.
    final class ProxyOverrideValidator {
        var rules: [any ProxyOverrideRule]

        init(rules: [any ProxyOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyOverride) -> [String] {
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

        func requireValid(_ item: ProxyOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyOverride]) -> [String: [String]] {
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

    static func defaultProxyOverrideValidator() -> ProxyOverrideValidator {
        return ProxyOverrideValidator(
            rules: [
                ProxyOverrideCodePrefixRule(prefix: "X"),
                ProxyOverrideCodeLengthRule(maxLength: 32),
                ProxyOverrideApprovedGuardRule(limit: 80),
                ProxyOverrideExpiresAtRangeRule(min: 64, max: 86400),
                ProxyOverrideRequiredCodeRule(message: "proxy override needs a value"),
            ]
        )
    }
}
