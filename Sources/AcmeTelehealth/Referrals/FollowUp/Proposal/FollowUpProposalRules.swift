import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up proposal must pass. Check returns its problems, or none.
    protocol FollowUpProposalRule {
        func check(_ item: FollowUpProposal) -> [String]
    }

    final class FollowUpProposalStartsAtRangeRule: FollowUpProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpProposal) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpProposalAllowedTitleRule: FollowUpProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FollowUpProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is stale"]
            }
            return []
        }
    }

    final class FollowUpProposalWindowRule: FollowUpProposalRule {
        var maxSpan: Int

        init(maxSpan: Int) {
            self.maxSpan = maxSpan
        }

        func check(_ item: FollowUpProposal) -> [String] {
            if item.startsAt > item.endsAt {
                return ["starts at is after ends at"]
            }
            if maxSpan > 0 && (item.endsAt - item.startsAt > maxSpan) {
                return ["spans more than \(maxSpan) seconds"]
            }
            return []
        }
    }

    final class FollowUpProposalCodeLengthRule: FollowUpProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up proposal.
    final class FollowUpProposalValidator {
        var rules: [any FollowUpProposalRule]

        init(rules: [any FollowUpProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpProposal]) -> [String: [String]] {
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

    static func defaultFollowUpProposalValidator() -> FollowUpProposalValidator {
        return FollowUpProposalValidator(
            rules: [
                FollowUpProposalStartsAtRangeRule(min: 120, max: 255),
                FollowUpProposalAllowedTitleRule(allowed: ["strict", "weighted", "rolling"]),
                FollowUpProposalWindowRule(maxSpan: 86400),
                FollowUpProposalCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
