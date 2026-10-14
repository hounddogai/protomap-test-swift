import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a strict substitution proposal must pass. Check returns its problems, or none.
    protocol StrictSubstitutionProposalRule {
        func check(_ item: StrictSubstitutionProposal) -> [String]
    }

    final class StrictSubstitutionProposalRequiredCodeRule: StrictSubstitutionProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSubstitutionProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSubstitutionProposalAttemptsRangeRule: StrictSubstitutionProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSubstitutionProposal) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictSubstitutionProposalVersionRangeRule: StrictSubstitutionProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictSubstitutionProposal) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictSubstitutionProposalNameLengthRule: StrictSubstitutionProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSubstitutionProposal) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictSubstitutionProposalCodePrefixRule: StrictSubstitutionProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictSubstitutionProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict substitution proposal.
    final class StrictSubstitutionProposalValidator {
        var rules: [any StrictSubstitutionProposalRule]

        init(rules: [any StrictSubstitutionProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSubstitutionProposal) -> [String] {
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

        func requireValid(_ item: StrictSubstitutionProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSubstitutionProposal]) -> [String: [String]] {
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

    static func defaultStrictSubstitutionProposalValidator() -> StrictSubstitutionProposalValidator {
        return StrictSubstitutionProposalValidator(
            rules: [
                StrictSubstitutionProposalRequiredCodeRule(message: "strict substitution proposal needs an entry"),
                StrictSubstitutionProposalAttemptsRangeRule(min: 64, max: 120),
                StrictSubstitutionProposalVersionRangeRule(min: 80, max: 1000),
                StrictSubstitutionProposalNameLengthRule(maxLength: 64),
                StrictSubstitutionProposalCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
