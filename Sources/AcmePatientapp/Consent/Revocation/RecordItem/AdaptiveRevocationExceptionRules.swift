import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive revocation exception must pass. Check returns its problems, or none.
    protocol AdaptiveRevocationExceptionRule {
        func check(_ item: AdaptiveRevocationException) -> [String]
    }

    final class AdaptiveRevocationExceptionRequiredCodeRule: AdaptiveRevocationExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRevocationException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRevocationExceptionRequiredNameRule: AdaptiveRevocationExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRevocationException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRevocationExceptionCodePrefixRule: AdaptiveRevocationExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveRevocationException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveRevocationExceptionCodeLengthRule: AdaptiveRevocationExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRevocationException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRevocationExceptionVisibleGuardRule: AdaptiveRevocationExceptionRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AdaptiveRevocationException) -> [String] {
            if item.visible && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive revocation exception.
    final class AdaptiveRevocationExceptionValidator {
        var rules: [any AdaptiveRevocationExceptionRule]

        init(rules: [any AdaptiveRevocationExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRevocationException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveRevocationException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRevocationException]) -> [String: [String]] {
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

    static func defaultAdaptiveRevocationExceptionValidator() -> AdaptiveRevocationExceptionValidator {
        return AdaptiveRevocationExceptionValidator(
            rules: [
                AdaptiveRevocationExceptionRequiredCodeRule(message: "adaptive revocation exception needs this field"),
                AdaptiveRevocationExceptionRequiredNameRule(message: "adaptive revocation exception needs this field"),
                AdaptiveRevocationExceptionCodePrefixRule(prefix: "X"),
                AdaptiveRevocationExceptionCodeLengthRule(maxLength: 32),
                AdaptiveRevocationExceptionVisibleGuardRule(limit: 255),
            ]
        )
    }
}
