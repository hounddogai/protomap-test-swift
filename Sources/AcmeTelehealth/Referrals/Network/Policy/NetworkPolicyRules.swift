import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network policy must pass. Check returns its problems, or none.
    protocol NetworkPolicyRule {
        func check(_ item: NetworkPolicy) -> [String]
    }

    final class NetworkPolicyFacilityLengthRule: NetworkPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkPolicy) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkPolicyCodePrefixRule: NetworkPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: NetworkPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class NetworkPolicyTitleLengthRule: NetworkPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkPolicy) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network policy.
    final class NetworkPolicyValidator {
        var rules: [any NetworkPolicyRule]

        init(rules: [any NetworkPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkPolicy) -> [String] {
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

        func requireValid(_ item: NetworkPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkPolicy]) -> [String: [String]] {
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

    static func defaultNetworkPolicyValidator() -> NetworkPolicyValidator {
        return NetworkPolicyValidator(
            rules: [
                NetworkPolicyFacilityLengthRule(maxLength: 1000),
                NetworkPolicyCodePrefixRule(prefix: "REF"),
                NetworkPolicyTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
