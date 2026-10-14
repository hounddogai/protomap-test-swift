import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default cleaning proposal must pass. Check returns its problems, or none.
    protocol DefaultCleaningProposalRule {
        func check(_ item: DefaultCleaningProposal) -> [String]
    }

    final class DefaultCleaningProposalAmountRangeRule: DefaultCleaningProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCleaningProposal) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCleaningProposalPinnedGuardRule: DefaultCleaningProposalRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultCleaningProposal) -> [String] {
            if item.pinned && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class DefaultCleaningProposalRequiredCategoryRule: DefaultCleaningProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCleaningProposal) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCleaningProposalSegmentLengthRule: DefaultCleaningProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCleaningProposal) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default cleaning proposal.
    final class DefaultCleaningProposalValidator {
        var rules: [any DefaultCleaningProposalRule]

        init(rules: [any DefaultCleaningProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCleaningProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCleaningProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCleaningProposal]) -> [String: [String]] {
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

    static func defaultDefaultCleaningProposalValidator() -> DefaultCleaningProposalValidator {
        return DefaultCleaningProposalValidator(
            rules: [
                DefaultCleaningProposalAmountRangeRule(min: 8.2, max: 97.9),
                DefaultCleaningProposalPinnedGuardRule(limit: 16),
                DefaultCleaningProposalRequiredCategoryRule(message: "default cleaning proposal needs this field"),
                DefaultCleaningProposalSegmentLengthRule(maxLength: 86400),
            ]
        )
    }
}
