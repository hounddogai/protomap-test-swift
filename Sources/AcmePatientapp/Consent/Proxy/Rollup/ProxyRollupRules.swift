import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy rollup must pass. Check returns its problems, or none.
    protocol ProxyRollupRule {
        func check(_ item: ProxyRollup) -> [String]
    }

    final class ProxyRollupRequiredNameRule: ProxyRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyRollupCodeLengthRule: ProxyRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyRollupCodePrefixRule: ProxyRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyRollupRequiredTitleRule: ProxyRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy rollup.
    final class ProxyRollupValidator {
        var rules: [any ProxyRollupRule]

        init(rules: [any ProxyRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyRollup) -> [String] {
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

        func requireValid(_ item: ProxyRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyRollup]) -> [String: [String]] {
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

    static func defaultProxyRollupValidator() -> ProxyRollupValidator {
        return ProxyRollupValidator(
            rules: [
                ProxyRollupRequiredNameRule(message: "proxy rollup needs a value"),
                ProxyRollupCodeLengthRule(maxLength: 80),
                ProxyRollupCodePrefixRule(prefix: "REF"),
                ProxyRollupRequiredTitleRule(message: "proxy rollup needs this field"),
            ]
        )
    }
}
