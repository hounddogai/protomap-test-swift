import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive dispense proposal must pass. Check returns its problems, or none.
    protocol AdaptiveDispenseProposalRule {
        func check(_ item: AdaptiveDispenseProposal) -> [String]
    }

    final class AdaptiveDispenseProposalCodePrefixRule: AdaptiveDispenseProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveDispenseProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveDispenseProposalRequiredTitleRule: AdaptiveDispenseProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDispenseProposal) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveDispenseProposalLimitRangeRule: AdaptiveDispenseProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveDispenseProposal) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveDispenseProposalAllowedCodeRule: AdaptiveDispenseProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveDispenseProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive dispense proposal.
    final class AdaptiveDispenseProposalValidator {
        var rules: [any AdaptiveDispenseProposalRule]

        init(rules: [any AdaptiveDispenseProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveDispenseProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveDispenseProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveDispenseProposal]) -> [String: [String]] {
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

    static func defaultAdaptiveDispenseProposalValidator() -> AdaptiveDispenseProposalValidator {
        return AdaptiveDispenseProposalValidator(
            rules: [
                AdaptiveDispenseProposalCodePrefixRule(prefix: "Q"),
                AdaptiveDispenseProposalRequiredTitleRule(message: "adaptive dispense proposal needs this field"),
                AdaptiveDispenseProposalLimitRangeRule(min: 32, max: 120),
                AdaptiveDispenseProposalAllowedCodeRule(allowed: ["default"]),
            ]
        )
    }
}
