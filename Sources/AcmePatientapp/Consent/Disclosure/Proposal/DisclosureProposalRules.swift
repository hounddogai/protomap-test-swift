import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure proposal must pass. Check returns its problems, or none.
    protocol DisclosureProposalRule {
        func check(_ item: DisclosureProposal) -> [String]
    }

    final class DisclosureProposalCountryLengthRule: DisclosureProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureProposal) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureProposalAmountRangeRule: DisclosureProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureProposal) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosureProposalContactEmailLengthRule: DisclosureProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureProposal) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureProposalEndsAtRangeRule: DisclosureProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureProposal) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a disclosure proposal.
    final class DisclosureProposalValidator {
        var rules: [any DisclosureProposalRule]

        init(rules: [any DisclosureProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureProposal]) -> [String: [String]] {
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

    static func defaultDisclosureProposalValidator() -> DisclosureProposalValidator {
        return DisclosureProposalValidator(
            rules: [
                DisclosureProposalCountryLengthRule(maxLength: 86400),
                DisclosureProposalAmountRangeRule(min: 6.6, max: 3133.4),
                DisclosureProposalContactEmailLengthRule(maxLength: 64),
                DisclosureProposalEndsAtRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
