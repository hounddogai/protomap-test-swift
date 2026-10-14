import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy tier must pass. Check returns its problems, or none.
    protocol ProxyTierRule {
        func check(_ item: ProxyTier) -> [String]
    }

    final class ProxyTierCodeLengthRule: ProxyTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyTierRequiredTimezoneRule: ProxyTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyTier) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyTierLabelLengthRule: ProxyTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyTierRequiredCodeRule: ProxyTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyTierRequiredLabelRule: ProxyTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyTierApprovedGuardRule: ProxyTierRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ProxyTier) -> [String] {
            if item.approved && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy tier.
    final class ProxyTierValidator {
        var rules: [any ProxyTierRule]

        init(rules: [any ProxyTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyTier]) -> [String: [String]] {
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

    static func defaultProxyTierValidator() -> ProxyTierValidator {
        return ProxyTierValidator(
            rules: [
                ProxyTierCodeLengthRule(maxLength: 1000),
                ProxyTierRequiredTimezoneRule(message: "proxy tier needs an entry"),
                ProxyTierLabelLengthRule(maxLength: 1000),
                ProxyTierRequiredCodeRule(message: "proxy tier needs an entry"),
                ProxyTierRequiredLabelRule(message: "proxy tier needs an entry"),
                ProxyTierApprovedGuardRule(limit: 9.2),
            ]
        )
    }
}
