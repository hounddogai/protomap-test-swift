import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network proposal must pass. Check returns its problems, or none.
    protocol NetworkProposalRule {
        func check(_ item: NetworkProposal) -> [String]
    }

    final class NetworkProposalVisibleGuardRule: NetworkProposalRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: NetworkProposal) -> [String] {
            if item.visible && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class NetworkProposalLabelLengthRule: NetworkProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkProposalRequiredSummaryRule: NetworkProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkProposal) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkProposalSequenceRangeRule: NetworkProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkProposal) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkProposalCodePrefixRule: NetworkProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: NetworkProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a network proposal.
    final class NetworkProposalValidator {
        var rules: [any NetworkProposalRule]

        init(rules: [any NetworkProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkProposal) -> [String] {
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

        func requireValid(_ item: NetworkProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkProposal]) -> [String: [String]] {
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

    static func defaultNetworkProposalValidator() -> NetworkProposalValidator {
        return NetworkProposalValidator(
            rules: [
                NetworkProposalVisibleGuardRule(limit: 3600),
                NetworkProposalLabelLengthRule(maxLength: 80),
                NetworkProposalRequiredSummaryRule(message: "network proposal needs an entry"),
                NetworkProposalSequenceRangeRule(min: 32, max: 32),
                NetworkProposalCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
