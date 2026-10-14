import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form proposal must pass. Check returns its problems, or none.
    protocol ConsentFormProposalRule {
        func check(_ item: ConsentFormProposal) -> [String]
    }

    final class ConsentFormProposalRequiredCodeRule: ConsentFormProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormProposalCodePrefixRule: ConsentFormProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ConsentFormProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ConsentFormProposalMarginRangeRule: ConsentFormProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormProposal) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form proposal.
    final class ConsentFormProposalValidator {
        var rules: [any ConsentFormProposalRule]

        init(rules: [any ConsentFormProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormProposal]) -> [String: [String]] {
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

    static func defaultConsentFormProposalValidator() -> ConsentFormProposalValidator {
        return ConsentFormProposalValidator(
            rules: [
                ConsentFormProposalRequiredCodeRule(message: "consent form proposal needs this field"),
                ConsentFormProposalCodePrefixRule(prefix: "X"),
                ConsentFormProposalMarginRangeRule(min: 1.1, max: 154.1),
            ]
        )
    }
}
