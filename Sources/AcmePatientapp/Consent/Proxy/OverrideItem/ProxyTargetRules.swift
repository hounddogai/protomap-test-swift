import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy target must pass. Check returns its problems, or none.
    protocol ProxyTargetRule {
        func check(_ item: ProxyTarget) -> [String]
    }

    final class ProxyTargetActiveGuardRule: ProxyTargetRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ProxyTarget) -> [String] {
            if item.active && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ProxyTargetRequiredNameRule: ProxyTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyTargetCodeLengthRule: ProxyTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyTargetRequiredExternalRefRule: ProxyTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyTarget) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyTargetRequiredCodeRule: ProxyTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy target.
    final class ProxyTargetValidator {
        var rules: [any ProxyTargetRule]

        init(rules: [any ProxyTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyTarget) -> [String] {
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

        func requireValid(_ item: ProxyTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyTarget]) -> [String: [String]] {
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

    static func defaultProxyTargetValidator() -> ProxyTargetValidator {
        return ProxyTargetValidator(
            rules: [
                ProxyTargetActiveGuardRule(limit: 9.3),
                ProxyTargetRequiredNameRule(message: "proxy target needs this field"),
                ProxyTargetCodeLengthRule(maxLength: 16),
                ProxyTargetRequiredExternalRefRule(message: "proxy target needs an entry"),
                ProxyTargetRequiredCodeRule(message: "proxy target needs an entry"),
            ]
        )
    }
}
