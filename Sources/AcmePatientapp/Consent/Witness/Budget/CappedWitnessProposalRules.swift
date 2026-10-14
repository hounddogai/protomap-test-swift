import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped witness proposal must pass. Check returns its problems, or none.
    protocol CappedWitnessProposalRule {
        func check(_ item: CappedWitnessProposal) -> [String]
    }

    final class CappedWitnessProposalRequiredNameRule: CappedWitnessProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedWitnessProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedWitnessProposalAllowedPhoneRule: CappedWitnessProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedWitnessProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is unknown"]
            }
            return []
        }
    }

    final class CappedWitnessProposalSequenceRangeRule: CappedWitnessProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedWitnessProposal) -> [String] {
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

    final class CappedWitnessProposalCodeLengthRule: CappedWitnessProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedWitnessProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedWitnessProposalGraceDaysRangeRule: CappedWitnessProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedWitnessProposal) -> [String] {
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

    final class CappedWitnessProposalCodePrefixRule: CappedWitnessProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedWitnessProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped witness proposal.
    final class CappedWitnessProposalValidator {
        var rules: [any CappedWitnessProposalRule]

        init(rules: [any CappedWitnessProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedWitnessProposal) -> [String] {
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

        func requireValid(_ item: CappedWitnessProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedWitnessProposal]) -> [String: [String]] {
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

    static func defaultCappedWitnessProposalValidator() -> CappedWitnessProposalValidator {
        return CappedWitnessProposalValidator(
            rules: [
                CappedWitnessProposalRequiredNameRule(message: "capped witness proposal needs this field"),
                CappedWitnessProposalAllowedPhoneRule(allowed: ["rolling"]),
                CappedWitnessProposalSequenceRangeRule(min: 32, max: 120),
                CappedWitnessProposalCodeLengthRule(maxLength: 1000),
                CappedWitnessProposalGraceDaysRangeRule(min: 32, max: 255),
                CappedWitnessProposalCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
