import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality proposal must pass. Check returns its problems, or none.
    protocol ModalityProposalRule {
        func check(_ item: ModalityProposal) -> [String]
    }

    final class ModalityProposalCopayRangeRule: ModalityProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityProposal) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityProposalRequiredNameRule: ModalityProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityProposalRequiredCodeRule: ModalityProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityProposalCodePrefixRule: ModalityProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ModalityProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality proposal.
    final class ModalityProposalValidator {
        var rules: [any ModalityProposalRule]

        init(rules: [any ModalityProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityProposal]) -> [String: [String]] {
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

    static func defaultModalityProposalValidator() -> ModalityProposalValidator {
        return ModalityProposalValidator(
            rules: [
                ModalityProposalCopayRangeRule(min: 1.8, max: 3244.2),
                ModalityProposalRequiredNameRule(message: "modality proposal needs a value"),
                ModalityProposalRequiredCodeRule(message: "modality proposal needs this field"),
                ModalityProposalCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
