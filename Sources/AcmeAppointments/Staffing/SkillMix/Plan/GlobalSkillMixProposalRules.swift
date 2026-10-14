import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global skill mix proposal must pass. Check returns its problems, or none.
    protocol GlobalSkillMixProposalRule {
        func check(_ item: GlobalSkillMixProposal) -> [String]
    }

    final class GlobalSkillMixProposalTitleLengthRule: GlobalSkillMixProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSkillMixProposal) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSkillMixProposalRequiredOwnerIDRule: GlobalSkillMixProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSkillMixProposal) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSkillMixProposalAllowedOwnerIDRule: GlobalSkillMixProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalSkillMixProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is blocked"]
            }
            return []
        }
    }

    final class GlobalSkillMixProposalCodePrefixRule: GlobalSkillMixProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalSkillMixProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalSkillMixProposalApprovedGuardRule: GlobalSkillMixProposalRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GlobalSkillMixProposal) -> [String] {
            if item.approved && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a global skill mix proposal.
    final class GlobalSkillMixProposalValidator {
        var rules: [any GlobalSkillMixProposalRule]

        init(rules: [any GlobalSkillMixProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSkillMixProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalSkillMixProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSkillMixProposal]) -> [String: [String]] {
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

    static func defaultGlobalSkillMixProposalValidator() -> GlobalSkillMixProposalValidator {
        return GlobalSkillMixProposalValidator(
            rules: [
                GlobalSkillMixProposalTitleLengthRule(maxLength: 32),
                GlobalSkillMixProposalRequiredOwnerIDRule(message: "global skill mix proposal needs this field"),
                GlobalSkillMixProposalAllowedOwnerIDRule(allowed: ["global"]),
                GlobalSkillMixProposalCodePrefixRule(prefix: "Q"),
                GlobalSkillMixProposalApprovedGuardRule(limit: 7.5),
            ]
        )
    }
}
