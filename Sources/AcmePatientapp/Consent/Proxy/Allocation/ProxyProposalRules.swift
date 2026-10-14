import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy proposal must pass. Check returns its problems, or none.
    protocol ProxyProposalRule {
        func check(_ item: ProxyProposal) -> [String]
    }

    final class ProxyProposalAllowedCodeRule: ProxyProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class ProxyProposalRequiredNameRule: ProxyProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyProposalRequiredFacilityRule: ProxyProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyProposal) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyProposalCodePrefixRule: ProxyProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyProposalRequiredCodeRule: ProxyProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy proposal.
    final class ProxyProposalValidator {
        var rules: [any ProxyProposalRule]

        init(rules: [any ProxyProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyProposal) -> [String] {
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

        func requireValid(_ item: ProxyProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyProposal]) -> [String: [String]] {
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

    static func defaultProxyProposalValidator() -> ProxyProposalValidator {
        return ProxyProposalValidator(
            rules: [
                ProxyProposalAllowedCodeRule(allowed: ["seasonal", "rolling"]),
                ProxyProposalRequiredNameRule(message: "proxy proposal needs an entry"),
                ProxyProposalRequiredFacilityRule(message: "proxy proposal needs a value"),
                ProxyProposalCodePrefixRule(prefix: "ACM"),
                ProxyProposalRequiredCodeRule(message: "proxy proposal needs this field"),
            ]
        )
    }
}
