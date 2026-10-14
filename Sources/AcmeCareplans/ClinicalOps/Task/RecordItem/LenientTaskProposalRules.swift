import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient task proposal must pass. Check returns its problems, or none.
    protocol LenientTaskProposalRule {
        func check(_ item: LenientTaskProposal) -> [String]
    }

    final class LenientTaskProposalRequiredCodeRule: LenientTaskProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientTaskProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientTaskProposalRequiredLabelRule: LenientTaskProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientTaskProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientTaskProposalAllowedCodeRule: LenientTaskProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientTaskProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class LenientTaskProposalNotesLengthRule: LenientTaskProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientTaskProposal) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient task proposal.
    final class LenientTaskProposalValidator {
        var rules: [any LenientTaskProposalRule]

        init(rules: [any LenientTaskProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientTaskProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientTaskProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientTaskProposal]) -> [String: [String]] {
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

    static func defaultLenientTaskProposalValidator() -> LenientTaskProposalValidator {
        return LenientTaskProposalValidator(
            rules: [
                LenientTaskProposalRequiredCodeRule(message: "lenient task proposal needs a value"),
                LenientTaskProposalRequiredLabelRule(message: "lenient task proposal needs an entry"),
                LenientTaskProposalAllowedCodeRule(allowed: ["adaptive", "default"]),
                LenientTaskProposalNotesLengthRule(maxLength: 64),
            ]
        )
    }
}
