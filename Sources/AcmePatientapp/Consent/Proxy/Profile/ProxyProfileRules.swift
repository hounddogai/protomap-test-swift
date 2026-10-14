import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy profile must pass. Check returns its problems, or none.
    protocol ProxyProfileRule {
        func check(_ item: ProxyProfile) -> [String]
    }

    final class ProxyProfileAllowedCodeRule: ProxyProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class ProxyProfileCodePrefixRule: ProxyProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyProfileCodeLengthRule: ProxyProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyProfileRequiredTitleRule: ProxyProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyProfile) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy profile.
    final class ProxyProfileValidator {
        var rules: [any ProxyProfileRule]

        init(rules: [any ProxyProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyProfile]) -> [String: [String]] {
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

    static func defaultProxyProfileValidator() -> ProxyProfileValidator {
        return ProxyProfileValidator(
            rules: [
                ProxyProfileAllowedCodeRule(allowed: ["default", "legacy", "scheduled"]),
                ProxyProfileCodePrefixRule(prefix: "REF"),
                ProxyProfileCodeLengthRule(maxLength: 86400),
                ProxyProfileRequiredTitleRule(message: "proxy profile needs an entry"),
            ]
        )
    }
}
