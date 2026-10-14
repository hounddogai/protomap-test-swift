import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient outreach proposal must pass. Check returns its problems, or none.
    protocol LenientOutreachProposalRule {
        func check(_ item: LenientOutreachProposal) -> [String]
    }

    final class LenientOutreachProposalEncounterIDLengthRule: LenientOutreachProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOutreachProposal) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientOutreachProposalExternalRefLengthRule: LenientOutreachProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOutreachProposal) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientOutreachProposalAllowedLabelRule: LenientOutreachProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientOutreachProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient outreach proposal.
    final class LenientOutreachProposalValidator {
        var rules: [any LenientOutreachProposalRule]

        init(rules: [any LenientOutreachProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientOutreachProposal) -> [String] {
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

        func requireValid(_ item: LenientOutreachProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientOutreachProposal]) -> [String: [String]] {
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

    static func defaultLenientOutreachProposalValidator() -> LenientOutreachProposalValidator {
        return LenientOutreachProposalValidator(
            rules: [
                LenientOutreachProposalEncounterIDLengthRule(maxLength: 120),
                LenientOutreachProposalExternalRefLengthRule(maxLength: 64),
                LenientOutreachProposalAllowedLabelRule(allowed: ["fallback", "manual"]),
            ]
        )
    }
}
