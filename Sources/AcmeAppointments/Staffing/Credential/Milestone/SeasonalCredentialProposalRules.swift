import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal credential proposal must pass. Check returns its problems, or none.
    protocol SeasonalCredentialProposalRule {
        func check(_ item: SeasonalCredentialProposal) -> [String]
    }

    final class SeasonalCredentialProposalTitleLengthRule: SeasonalCredentialProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCredentialProposal) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCredentialProposalUpdatedAtRangeRule: SeasonalCredentialProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCredentialProposal) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalCredentialProposalRequiredNameRule: SeasonalCredentialProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCredentialProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCredentialProposalRequiredCodeRule: SeasonalCredentialProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCredentialProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCredentialProposalNameLengthRule: SeasonalCredentialProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCredentialProposal) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal credential proposal.
    final class SeasonalCredentialProposalValidator {
        var rules: [any SeasonalCredentialProposalRule]

        init(rules: [any SeasonalCredentialProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCredentialProposal) -> [String] {
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

        func requireValid(_ item: SeasonalCredentialProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCredentialProposal]) -> [String: [String]] {
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

    static func defaultSeasonalCredentialProposalValidator() -> SeasonalCredentialProposalValidator {
        return SeasonalCredentialProposalValidator(
            rules: [
                SeasonalCredentialProposalTitleLengthRule(maxLength: 1000),
                SeasonalCredentialProposalUpdatedAtRangeRule(min: 16, max: 16),
                SeasonalCredentialProposalRequiredNameRule(message: "seasonal credential proposal needs an entry"),
                SeasonalCredentialProposalRequiredCodeRule(message: "seasonal credential proposal needs this field"),
                SeasonalCredentialProposalNameLengthRule(maxLength: 255),
            ]
        )
    }
}
