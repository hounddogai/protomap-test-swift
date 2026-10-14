import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation proposal must pass. Check returns its problems, or none.
    protocol RevocationProposalRule {
        func check(_ item: RevocationProposal) -> [String]
    }

    final class RevocationProposalActiveGuardRule: RevocationProposalRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RevocationProposal) -> [String] {
            if item.active && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class RevocationProposalLabelLengthRule: RevocationProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationProposalRatioRangeRule: RevocationProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationProposal) -> [String] {
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

    final class RevocationProposalStartsAtRangeRule: RevocationProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationProposal) -> [String] {
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

    final class RevocationProposalCreatedAtRangeRule: RevocationProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationProposal) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RevocationProposalRequiredExternalRefRule: RevocationProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationProposal) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a revocation proposal.
    final class RevocationProposalValidator {
        var rules: [any RevocationProposalRule]

        init(rules: [any RevocationProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationProposal) -> [String] {
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

        func requireValid(_ item: RevocationProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationProposal]) -> [String: [String]] {
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

    static func defaultRevocationProposalValidator() -> RevocationProposalValidator {
        return RevocationProposalValidator(
            rules: [
                RevocationProposalActiveGuardRule(limit: 32),
                RevocationProposalLabelLengthRule(maxLength: 120),
                RevocationProposalRatioRangeRule(min: 5.1, max: 3540.7),
                RevocationProposalStartsAtRangeRule(min: 64, max: 1000),
                RevocationProposalCreatedAtRangeRule(min: 16, max: 1000),
                RevocationProposalRequiredExternalRefRule(message: "revocation proposal needs a value"),
            ]
        )
    }
}
