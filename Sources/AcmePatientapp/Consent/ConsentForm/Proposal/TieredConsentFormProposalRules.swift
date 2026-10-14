import AcmePlatform
import Foundation

extension Consent {
    /// A rule a tiered consent form proposal must pass. Check returns its problems, or none.
    protocol TieredConsentFormProposalRule {
        func check(_ item: TieredConsentFormProposal) -> [String]
    }

    final class TieredConsentFormProposalRequiredLabelRule: TieredConsentFormProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredConsentFormProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredConsentFormProposalCodeLengthRule: TieredConsentFormProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredConsentFormProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredConsentFormProposalPriorityRangeRule: TieredConsentFormProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredConsentFormProposal) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredConsentFormProposalScoreRangeRule: TieredConsentFormProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredConsentFormProposal) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredConsentFormProposalCodePrefixRule: TieredConsentFormProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredConsentFormProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredConsentFormProposalLabelLengthRule: TieredConsentFormProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredConsentFormProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered consent form proposal.
    final class TieredConsentFormProposalValidator {
        var rules: [any TieredConsentFormProposalRule]

        init(rules: [any TieredConsentFormProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredConsentFormProposal) -> [String] {
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

        func requireValid(_ item: TieredConsentFormProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredConsentFormProposal]) -> [String: [String]] {
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

    static func defaultTieredConsentFormProposalValidator() -> TieredConsentFormProposalValidator {
        return TieredConsentFormProposalValidator(
            rules: [
                TieredConsentFormProposalRequiredLabelRule(message: "tiered consent form proposal needs this field"),
                TieredConsentFormProposalCodeLengthRule(maxLength: 86400),
                TieredConsentFormProposalPriorityRangeRule(min: 1000, max: 86400),
                TieredConsentFormProposalScoreRangeRule(min: 0.9, max: 1748.8),
                TieredConsentFormProposalCodePrefixRule(prefix: "X"),
                TieredConsentFormProposalLabelLengthRule(maxLength: 80),
            ]
        )
    }
}
