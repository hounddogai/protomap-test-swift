import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy allocation must pass. Check returns its problems, or none.
    protocol ProxyAllocationRule {
        func check(_ item: ProxyAllocation) -> [String]
    }

    final class ProxyAllocationAllowedNameRule: ProxyAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class ProxyAllocationCodePrefixRule: ProxyAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyAllocationNameLengthRule: ProxyAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyAllocation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyAllocationChannelLengthRule: ProxyAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyAllocation) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyAllocationRequiredNameRule: ProxyAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyAllocation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyAllocationRequiredCodeRule: ProxyAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy allocation.
    final class ProxyAllocationValidator {
        var rules: [any ProxyAllocationRule]

        init(rules: [any ProxyAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyAllocation]) -> [String: [String]] {
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

    static func defaultProxyAllocationValidator() -> ProxyAllocationValidator {
        return ProxyAllocationValidator(
            rules: [
                ProxyAllocationAllowedNameRule(allowed: ["lenient"]),
                ProxyAllocationCodePrefixRule(prefix: "X"),
                ProxyAllocationNameLengthRule(maxLength: 3600),
                ProxyAllocationChannelLengthRule(maxLength: 86400),
                ProxyAllocationRequiredNameRule(message: "proxy allocation needs an entry"),
                ProxyAllocationRequiredCodeRule(message: "proxy allocation needs this field"),
            ]
        )
    }
}
