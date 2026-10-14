import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board proposal must pass. Check returns its problems, or none.
    protocol BedBoardProposalRule {
        func check(_ item: BedBoardProposal) -> [String]
    }

    final class BedBoardProposalRequiredCodeRule: BedBoardProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardProposalDiscountRangeRule: BedBoardProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardProposal) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardProposalTimezoneLengthRule: BedBoardProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardProposal) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardProposalCodePrefixRule: BedBoardProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BedBoardProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board proposal.
    final class BedBoardProposalValidator {
        var rules: [any BedBoardProposalRule]

        init(rules: [any BedBoardProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardProposal]) -> [String: [String]] {
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

    static func defaultBedBoardProposalValidator() -> BedBoardProposalValidator {
        return BedBoardProposalValidator(
            rules: [
                BedBoardProposalRequiredCodeRule(message: "bed board proposal needs an entry"),
                BedBoardProposalDiscountRangeRule(min: 9.2, max: 2641.2),
                BedBoardProposalTimezoneLengthRule(maxLength: 86400),
                BedBoardProposalCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
