import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy claim must pass. Check returns its problems, or none.
    protocol ProxyClaimRule {
        func check(_ item: ProxyClaim) -> [String]
    }

    final class ProxyClaimAllowedTitleRule: ProxyClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    final class ProxyClaimRequiredTitleRule: ProxyClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyClaimCodeLengthRule: ProxyClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyClaimUpdatedAtRangeRule: ProxyClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyClaim) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProxyClaimRequiredProcedureCodeRule: ProxyClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyClaim) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy claim.
    final class ProxyClaimValidator {
        var rules: [any ProxyClaimRule]

        init(rules: [any ProxyClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyClaim) -> [String] {
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

        func requireValid(_ item: ProxyClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyClaim]) -> [String: [String]] {
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

    static func defaultProxyClaimValidator() -> ProxyClaimValidator {
        return ProxyClaimValidator(
            rules: [
                ProxyClaimAllowedTitleRule(allowed: ["primary", "capped"]),
                ProxyClaimRequiredTitleRule(message: "proxy claim needs an entry"),
                ProxyClaimCodeLengthRule(maxLength: 80),
                ProxyClaimUpdatedAtRangeRule(min: 80, max: 80),
                ProxyClaimRequiredProcedureCodeRule(message: "proxy claim needs a value"),
            ]
        )
    }
}
