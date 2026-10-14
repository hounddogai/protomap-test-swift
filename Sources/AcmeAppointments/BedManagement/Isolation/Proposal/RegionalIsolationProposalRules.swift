import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a regional isolation proposal must pass. Check returns its problems, or none.
    protocol RegionalIsolationProposalRule {
        func check(_ item: RegionalIsolationProposal) -> [String]
    }

    final class RegionalIsolationProposalMarginRangeRule: RegionalIsolationProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalIsolationProposal) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalIsolationProposalRequiredTitleRule: RegionalIsolationProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalIsolationProposal) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalIsolationProposalLimitRangeRule: RegionalIsolationProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalIsolationProposal) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalIsolationProposalCodeLengthRule: RegionalIsolationProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalIsolationProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional isolation proposal.
    final class RegionalIsolationProposalValidator {
        var rules: [any RegionalIsolationProposalRule]

        init(rules: [any RegionalIsolationProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalIsolationProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalIsolationProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalIsolationProposal]) -> [String: [String]] {
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

    static func defaultRegionalIsolationProposalValidator() -> RegionalIsolationProposalValidator {
        return RegionalIsolationProposalValidator(
            rules: [
                RegionalIsolationProposalMarginRangeRule(min: 5.1, max: 4364.1),
                RegionalIsolationProposalRequiredTitleRule(message: "regional isolation proposal needs an entry"),
                RegionalIsolationProposalLimitRangeRule(min: 80, max: 255),
                RegionalIsolationProposalCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
