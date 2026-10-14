import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling read proposal must pass. Check returns its problems, or none.
    protocol RollingReadProposalRule {
        func check(_ item: RollingReadProposal) -> [String]
    }

    final class RollingReadProposalRequiredContactEmailRule: RollingReadProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingReadProposal) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingReadProposalCodePrefixRule: RollingReadProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingReadProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingReadProposalRequiredCurrencyRule: RollingReadProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingReadProposal) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingReadProposalRequiredTitleRule: RollingReadProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingReadProposal) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingReadProposalCurrencyLengthRule: RollingReadProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingReadProposal) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling read proposal.
    final class RollingReadProposalValidator {
        var rules: [any RollingReadProposalRule]

        init(rules: [any RollingReadProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingReadProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingReadProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingReadProposal]) -> [String: [String]] {
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

    static func defaultRollingReadProposalValidator() -> RollingReadProposalValidator {
        return RollingReadProposalValidator(
            rules: [
                RollingReadProposalRequiredContactEmailRule(message: "rolling read proposal needs an entry"),
                RollingReadProposalCodePrefixRule(prefix: "X"),
                RollingReadProposalRequiredCurrencyRule(message: "rolling read proposal needs a value"),
                RollingReadProposalRequiredTitleRule(message: "rolling read proposal needs this field"),
                RollingReadProposalCurrencyLengthRule(maxLength: 255),
            ]
        )
    }
}
