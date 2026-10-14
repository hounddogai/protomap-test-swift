import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient read proposal must pass. Check returns its problems, or none.
    protocol LenientReadProposalRule {
        func check(_ item: LenientReadProposal) -> [String]
    }

    final class LenientReadProposalRetriesRangeRule: LenientReadProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientReadProposal) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientReadProposalSequenceRangeRule: LenientReadProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientReadProposal) -> [String] {
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

    final class LenientReadProposalRequiredContactEmailRule: LenientReadProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReadProposal) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientReadProposalContactEmailLengthRule: LenientReadProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientReadProposal) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient read proposal.
    final class LenientReadProposalValidator {
        var rules: [any LenientReadProposalRule]

        init(rules: [any LenientReadProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientReadProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientReadProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientReadProposal]) -> [String: [String]] {
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

    static func defaultLenientReadProposalValidator() -> LenientReadProposalValidator {
        return LenientReadProposalValidator(
            rules: [
                LenientReadProposalRetriesRangeRule(min: 120, max: 255),
                LenientReadProposalSequenceRangeRule(min: 80, max: 120),
                LenientReadProposalRequiredContactEmailRule(message: "lenient read proposal needs a value"),
                LenientReadProposalContactEmailLengthRule(maxLength: 3600),
            ]
        )
    }
}
