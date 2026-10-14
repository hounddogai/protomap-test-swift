import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling closure proposal must pass. Check returns its problems, or none.
    protocol RollingClosureProposalRule {
        func check(_ item: RollingClosureProposal) -> [String]
    }

    final class RollingClosureProposalLimitRangeRule: RollingClosureProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingClosureProposal) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingClosureProposalCodeLengthRule: RollingClosureProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingClosureProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingClosureProposalAllowedUnitRule: RollingClosureProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingClosureProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is expired"]
            }
            return []
        }
    }

    final class RollingClosureProposalRateRangeRule: RollingClosureProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingClosureProposal) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingClosureProposalRequiredReviewerRule: RollingClosureProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingClosureProposal) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingClosureProposalLabelLengthRule: RollingClosureProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingClosureProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling closure proposal.
    final class RollingClosureProposalValidator {
        var rules: [any RollingClosureProposalRule]

        init(rules: [any RollingClosureProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingClosureProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingClosureProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingClosureProposal]) -> [String: [String]] {
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

    static func defaultRollingClosureProposalValidator() -> RollingClosureProposalValidator {
        return RollingClosureProposalValidator(
            rules: [
                RollingClosureProposalLimitRangeRule(min: 80, max: 1000),
                RollingClosureProposalCodeLengthRule(maxLength: 1000),
                RollingClosureProposalAllowedUnitRule(allowed: ["manual"]),
                RollingClosureProposalRateRangeRule(min: 4.9, max: 3189.7),
                RollingClosureProposalRequiredReviewerRule(message: "rolling closure proposal needs this field"),
                RollingClosureProposalLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
