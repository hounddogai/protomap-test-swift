import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default specimen proposal must pass. Check returns its problems, or none.
    protocol DefaultSpecimenProposalRule {
        func check(_ item: DefaultSpecimenProposal) -> [String]
    }

    final class DefaultSpecimenProposalRequiredCurrencyRule: DefaultSpecimenProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSpecimenProposal) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSpecimenProposalNameLengthRule: DefaultSpecimenProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSpecimenProposal) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultSpecimenProposalCodePrefixRule: DefaultSpecimenProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultSpecimenProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a default specimen proposal.
    final class DefaultSpecimenProposalValidator {
        var rules: [any DefaultSpecimenProposalRule]

        init(rules: [any DefaultSpecimenProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultSpecimenProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultSpecimenProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultSpecimenProposal]) -> [String: [String]] {
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

    static func defaultDefaultSpecimenProposalValidator() -> DefaultSpecimenProposalValidator {
        return DefaultSpecimenProposalValidator(
            rules: [
                DefaultSpecimenProposalRequiredCurrencyRule(message: "default specimen proposal needs an entry"),
                DefaultSpecimenProposalNameLengthRule(maxLength: 80),
                DefaultSpecimenProposalCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
