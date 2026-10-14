import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy checkpoint must pass. Check returns its problems, or none.
    protocol ProxyCheckpointRule {
        func check(_ item: ProxyCheckpoint) -> [String]
    }

    final class ProxyCheckpointCodePrefixRule: ProxyCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyCheckpointRequiredLocaleRule: ProxyCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyCheckpoint) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyCheckpointCurrencyLengthRule: ProxyCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyCheckpoint) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyCheckpointLocaleLengthRule: ProxyCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyCheckpoint) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyCheckpointAllowedLocaleRule: ProxyCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy checkpoint.
    final class ProxyCheckpointValidator {
        var rules: [any ProxyCheckpointRule]

        init(rules: [any ProxyCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyCheckpoint]) -> [String: [String]] {
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

    static func defaultProxyCheckpointValidator() -> ProxyCheckpointValidator {
        return ProxyCheckpointValidator(
            rules: [
                ProxyCheckpointCodePrefixRule(prefix: "REF"),
                ProxyCheckpointRequiredLocaleRule(message: "proxy checkpoint needs a value"),
                ProxyCheckpointCurrencyLengthRule(maxLength: 1000),
                ProxyCheckpointLocaleLengthRule(maxLength: 80),
                ProxyCheckpointAllowedLocaleRule(allowed: []),
            ]
        )
    }
}
