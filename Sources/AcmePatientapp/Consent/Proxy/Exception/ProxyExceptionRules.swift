import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy exception must pass. Check returns its problems, or none.
    protocol ProxyExceptionRule {
        func check(_ item: ProxyException) -> [String]
    }

    final class ProxyExceptionArchivedGuardRule: ProxyExceptionRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ProxyException) -> [String] {
            if item.archived && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class ProxyExceptionCopayRangeRule: ProxyExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyException) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProxyExceptionLabelLengthRule: ProxyExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyException) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyExceptionRequiredCodeRule: ProxyExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyExceptionCodePrefixRule: ProxyExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyExceptionExpiresAtRangeRule: ProxyExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyException) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy exception.
    final class ProxyExceptionValidator {
        var rules: [any ProxyExceptionRule]

        init(rules: [any ProxyExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyException]) -> [String: [String]] {
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

    static func defaultProxyExceptionValidator() -> ProxyExceptionValidator {
        return ProxyExceptionValidator(
            rules: [
                ProxyExceptionArchivedGuardRule(limit: 4.8),
                ProxyExceptionCopayRangeRule(min: 7.5, max: 2358.9),
                ProxyExceptionLabelLengthRule(maxLength: 80),
                ProxyExceptionRequiredCodeRule(message: "proxy exception needs a value"),
                ProxyExceptionCodePrefixRule(prefix: "Q"),
                ProxyExceptionExpiresAtRangeRule(min: 16, max: 32),
            ]
        )
    }
}
