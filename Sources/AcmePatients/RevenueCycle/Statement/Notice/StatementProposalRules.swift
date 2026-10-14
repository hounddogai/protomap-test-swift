import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement proposal must pass. Check returns its problems, or none.
    protocol StatementProposalRule {
        func check(_ item: StatementProposal) -> [String]
    }

    final class StatementProposalAllowedCodeRule: StatementProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StatementProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class StatementProposalCodePrefixRule: StatementProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StatementProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StatementProposalGraceDaysRangeRule: StatementProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementProposal) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementProposalRequiredChannelRule: StatementProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementProposal) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementProposalChannelLengthRule: StatementProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementProposal) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementProposalRequiredCodeRule: StatementProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a statement proposal.
    final class StatementProposalValidator {
        var rules: [any StatementProposalRule]

        init(rules: [any StatementProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementProposal]) -> [String: [String]] {
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

    static func defaultStatementProposalValidator() -> StatementProposalValidator {
        return StatementProposalValidator(
            rules: [
                StatementProposalAllowedCodeRule(allowed: ["default"]),
                StatementProposalCodePrefixRule(prefix: "REF"),
                StatementProposalGraceDaysRangeRule(min: 16, max: 80),
                StatementProposalRequiredChannelRule(message: "statement proposal needs an entry"),
                StatementProposalChannelLengthRule(maxLength: 120),
                StatementProposalRequiredCodeRule(message: "statement proposal needs this field"),
            ]
        )
    }
}
