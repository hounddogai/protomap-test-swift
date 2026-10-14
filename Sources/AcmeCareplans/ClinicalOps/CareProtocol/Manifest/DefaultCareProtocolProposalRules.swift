import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a default care protocol proposal must pass. Check returns its problems, or none.
    protocol DefaultCareProtocolProposalRule {
        func check(_ item: DefaultCareProtocolProposal) -> [String]
    }

    final class DefaultCareProtocolProposalCodePrefixRule: DefaultCareProtocolProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultCareProtocolProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolProposalRequiredTitleRule: DefaultCareProtocolProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCareProtocolProposal) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCareProtocolProposalAllowedCodeRule: DefaultCareProtocolProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultCareProtocolProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class DefaultCareProtocolProposalRequiredRegionRule: DefaultCareProtocolProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCareProtocolProposal) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default care protocol proposal.
    final class DefaultCareProtocolProposalValidatorExtra {
        var rules: [any DefaultCareProtocolProposalRule]

        init(rules: [any DefaultCareProtocolProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCareProtocolProposal) -> [String] {
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

        func requireValid(_ item: DefaultCareProtocolProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCareProtocolProposal]) -> [String: [String]] {
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

    static func defaultDefaultCareProtocolProposalValidator() -> DefaultCareProtocolProposalValidatorExtra {
        return DefaultCareProtocolProposalValidatorExtra(
            rules: [
                DefaultCareProtocolProposalCodePrefixRule(prefix: "X"),
                DefaultCareProtocolProposalRequiredTitleRule(message: "default care protocol proposal needs an entry"),
                DefaultCareProtocolProposalAllowedCodeRule(allowed: ["weighted", "regional"]),
                DefaultCareProtocolProposalRequiredRegionRule(
                    message: "default care protocol proposal needs this field"
                ),
            ]
        )
    }
}
