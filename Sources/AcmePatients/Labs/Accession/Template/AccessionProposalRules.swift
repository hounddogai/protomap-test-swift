import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession proposal must pass. Check returns its problems, or none.
    protocol AccessionProposalRule {
        func check(_ item: AccessionProposal) -> [String]
    }

    final class AccessionProposalCostRangeRule: AccessionProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionProposal) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionProposalCodePrefixRule: AccessionProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AccessionProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AccessionProposalAllowedPhoneRule: AccessionProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is above maximum"]
            }
            return []
        }
    }

    final class AccessionProposalCodeLengthRule: AccessionProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession proposal.
    final class AccessionProposalValidator {
        var rules: [any AccessionProposalRule]

        init(rules: [any AccessionProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionProposal]) -> [String: [String]] {
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

    static func defaultAccessionProposalValidator() -> AccessionProposalValidator {
        return AccessionProposalValidator(
            rules: [
                AccessionProposalCostRangeRule(min: 6.9, max: 2667.3),
                AccessionProposalCodePrefixRule(prefix: "ACM"),
                AccessionProposalAllowedPhoneRule(allowed: ["primary"]),
                AccessionProposalCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
