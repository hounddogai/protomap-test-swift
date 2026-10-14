import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range proposal must pass. Check returns its problems, or none.
    protocol ReferenceRangeProposalRule {
        func check(_ item: ReferenceRangeProposal) -> [String]
    }

    final class ReferenceRangeProposalRequiredPhoneRule: ReferenceRangeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeProposal) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeProposalPhoneLengthRule: ReferenceRangeProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeProposal) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeProposalRatioRangeRule: ReferenceRangeProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeProposal) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a reference range proposal.
    final class ReferenceRangeProposalValidator {
        var rules: [any ReferenceRangeProposalRule]

        init(rules: [any ReferenceRangeProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeProposal]) -> [String: [String]] {
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

    static func defaultReferenceRangeProposalValidator() -> ReferenceRangeProposalValidator {
        return ReferenceRangeProposalValidator(
            rules: [
                ReferenceRangeProposalRequiredPhoneRule(message: "reference range proposal needs an entry"),
                ReferenceRangeProposalPhoneLengthRule(maxLength: 120),
                ReferenceRangeProposalRatioRangeRule(min: 3.0, max: 2603.2),
            ]
        )
    }
}
