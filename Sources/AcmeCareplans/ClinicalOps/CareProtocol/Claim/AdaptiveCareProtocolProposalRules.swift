import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a adaptive care protocol proposal must pass. Check returns its problems, or none.
    protocol AdaptiveCareProtocolProposalRule {
        func check(_ item: AdaptiveCareProtocolProposal) -> [String]
    }

    final class AdaptiveCareProtocolProposalCodePrefixRule: AdaptiveCareProtocolProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveCareProtocolProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolProposalSequenceRangeRule: AdaptiveCareProtocolProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCareProtocolProposal) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolProposalLabelLengthRule: AdaptiveCareProtocolProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCareProtocolProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolProposalRevisionRangeRule: AdaptiveCareProtocolProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCareProtocolProposal) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveCareProtocolProposalAllowedLabelRule: AdaptiveCareProtocolProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveCareProtocolProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is below minimum"]
            }
            return []
        }
    }

    final class AdaptiveCareProtocolProposalStartsAtRangeRule: AdaptiveCareProtocolProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCareProtocolProposal) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive care protocol proposal.
    final class AdaptiveCareProtocolProposalValidator {
        var rules: [any AdaptiveCareProtocolProposalRule]

        init(rules: [any AdaptiveCareProtocolProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCareProtocolProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveCareProtocolProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCareProtocolProposal]) -> [String: [String]] {
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

    static func defaultAdaptiveCareProtocolProposalValidator() -> AdaptiveCareProtocolProposalValidator {
        return AdaptiveCareProtocolProposalValidator(
            rules: [
                AdaptiveCareProtocolProposalCodePrefixRule(prefix: "OPS"),
                AdaptiveCareProtocolProposalSequenceRangeRule(min: 64, max: 1000),
                AdaptiveCareProtocolProposalLabelLengthRule(maxLength: 80),
                AdaptiveCareProtocolProposalRevisionRangeRule(min: 120, max: 86400),
                AdaptiveCareProtocolProposalAllowedLabelRule(allowed: ["rolling", "strict", "primary"]),
                AdaptiveCareProtocolProposalStartsAtRangeRule(min: 16, max: 64),
            ]
        )
    }
}
