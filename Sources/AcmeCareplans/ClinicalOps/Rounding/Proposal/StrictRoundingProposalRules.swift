import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict rounding proposal must pass. Check returns its problems, or none.
    protocol StrictRoundingProposalRule {
        func check(_ item: StrictRoundingProposal) -> [String]
    }

    final class StrictRoundingProposalCreatedAtRangeRule: StrictRoundingProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictRoundingProposal) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictRoundingProposalRequiredCurrencyRule: StrictRoundingProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictRoundingProposal) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictRoundingProposalRequiredCodeRule: StrictRoundingProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictRoundingProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictRoundingProposalCurrencyLengthRule: StrictRoundingProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRoundingProposal) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictRoundingProposalCodeLengthRule: StrictRoundingProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRoundingProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictRoundingProposalLocaleLengthRule: StrictRoundingProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRoundingProposal) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict rounding proposal.
    final class StrictRoundingProposalValidator {
        var rules: [any StrictRoundingProposalRule]

        init(rules: [any StrictRoundingProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictRoundingProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictRoundingProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictRoundingProposal]) -> [String: [String]] {
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

    static func defaultStrictRoundingProposalValidator() -> StrictRoundingProposalValidator {
        return StrictRoundingProposalValidator(
            rules: [
                StrictRoundingProposalCreatedAtRangeRule(min: 16, max: 32),
                StrictRoundingProposalRequiredCurrencyRule(message: "strict rounding proposal needs an entry"),
                StrictRoundingProposalRequiredCodeRule(message: "strict rounding proposal needs a value"),
                StrictRoundingProposalCurrencyLengthRule(maxLength: 64),
                StrictRoundingProposalCodeLengthRule(maxLength: 86400),
                StrictRoundingProposalLocaleLengthRule(maxLength: 64),
            ]
        )
    }
}
