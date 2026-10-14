import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default courier proposal must pass. Check returns its problems, or none.
    protocol DefaultCourierProposalRule {
        func check(_ item: DefaultCourierProposal) -> [String]
    }

    final class DefaultCourierProposalCodePrefixRule: DefaultCourierProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultCourierProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultCourierProposalRequiredCodeRule: DefaultCourierProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCourierProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCourierProposalRequiredSourceRule: DefaultCourierProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCourierProposal) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCourierProposalSourceLengthRule: DefaultCourierProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCourierProposal) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCourierProposalAllowedCodeRule: DefaultCourierProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultCourierProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class DefaultCourierProposalExpiresAtRangeRule: DefaultCourierProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCourierProposal) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default courier proposal.
    final class DefaultCourierProposalValidator {
        var rules: [any DefaultCourierProposalRule]

        init(rules: [any DefaultCourierProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCourierProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCourierProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCourierProposal]) -> [String: [String]] {
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

    static func defaultDefaultCourierProposalValidator() -> DefaultCourierProposalValidator {
        return DefaultCourierProposalValidator(
            rules: [
                DefaultCourierProposalCodePrefixRule(prefix: "Q"),
                DefaultCourierProposalRequiredCodeRule(message: "default courier proposal needs a value"),
                DefaultCourierProposalRequiredSourceRule(message: "default courier proposal needs a value"),
                DefaultCourierProposalSourceLengthRule(maxLength: 120),
                DefaultCourierProposalAllowedCodeRule(allowed: ["capped", "seasonal", "seasonal"]),
                DefaultCourierProposalExpiresAtRangeRule(min: 16, max: 64),
            ]
        )
    }
}
