import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default recall proposal must pass. Check returns its problems, or none.
    protocol DefaultRecallProposalRule {
        func check(_ item: DefaultRecallProposal) -> [String]
    }

    final class DefaultRecallProposalVisitMinutesRangeRule: DefaultRecallProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRecallProposal) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultRecallProposalSpecialtyLengthRule: DefaultRecallProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRecallProposal) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRecallProposalRequiredDescriptionRule: DefaultRecallProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRecallProposal) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRecallProposalRequiredCodeRule: DefaultRecallProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRecallProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default recall proposal.
    final class DefaultRecallProposalValidator {
        var rules: [any DefaultRecallProposalRule]

        init(rules: [any DefaultRecallProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRecallProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultRecallProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRecallProposal]) -> [String: [String]] {
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

    static func defaultDefaultRecallProposalValidator() -> DefaultRecallProposalValidator {
        return DefaultRecallProposalValidator(
            rules: [
                DefaultRecallProposalVisitMinutesRangeRule(min: 1000, max: 3600),
                DefaultRecallProposalSpecialtyLengthRule(maxLength: 64),
                DefaultRecallProposalRequiredDescriptionRule(message: "default recall proposal needs an entry"),
                DefaultRecallProposalRequiredCodeRule(message: "default recall proposal needs a value"),
            ]
        )
    }
}
