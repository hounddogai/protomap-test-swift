import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy order set proposal must pass. Check returns its problems, or none.
    protocol LegacyOrderSetProposalRule {
        func check(_ item: LegacyOrderSetProposal) -> [String]
    }

    final class LegacyOrderSetProposalPayerLengthRule: LegacyOrderSetProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOrderSetProposal) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyOrderSetProposalRequiredPayerRule: LegacyOrderSetProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyOrderSetProposal) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyOrderSetProposalRequiredCodeRule: LegacyOrderSetProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyOrderSetProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyOrderSetProposalCostRangeRule: LegacyOrderSetProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyOrderSetProposal) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy order set proposal.
    final class LegacyOrderSetProposalValidator {
        var rules: [any LegacyOrderSetProposalRule]

        init(rules: [any LegacyOrderSetProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyOrderSetProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyOrderSetProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyOrderSetProposal]) -> [String: [String]] {
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

    static func defaultLegacyOrderSetProposalValidator() -> LegacyOrderSetProposalValidator {
        return LegacyOrderSetProposalValidator(
            rules: [
                LegacyOrderSetProposalPayerLengthRule(maxLength: 80),
                LegacyOrderSetProposalRequiredPayerRule(message: "legacy order set proposal needs a value"),
                LegacyOrderSetProposalRequiredCodeRule(message: "legacy order set proposal needs this field"),
                LegacyOrderSetProposalCostRangeRule(min: 3.7, max: 4329.8),
            ]
        )
    }
}
