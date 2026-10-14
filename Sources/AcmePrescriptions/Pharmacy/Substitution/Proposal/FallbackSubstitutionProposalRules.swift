import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback substitution proposal must pass. Check returns its problems, or none.
    protocol FallbackSubstitutionProposalRule {
        func check(_ item: FallbackSubstitutionProposal) -> [String]
    }

    final class FallbackSubstitutionProposalAllowedLabelRule: FallbackSubstitutionProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackSubstitutionProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    final class FallbackSubstitutionProposalTagsLimitRule: FallbackSubstitutionProposalRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: FallbackSubstitutionProposal) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class FallbackSubstitutionProposalMinimumRangeRule: FallbackSubstitutionProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackSubstitutionProposal) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackSubstitutionProposalMarginRangeRule: FallbackSubstitutionProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackSubstitutionProposal) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a fallback substitution proposal.
    final class FallbackSubstitutionProposalValidator {
        var rules: [any FallbackSubstitutionProposalRule]

        init(rules: [any FallbackSubstitutionProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackSubstitutionProposal) -> [String] {
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

        func requireValid(_ item: FallbackSubstitutionProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackSubstitutionProposal]) -> [String: [String]] {
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

    static func defaultFallbackSubstitutionProposalValidator() -> FallbackSubstitutionProposalValidator {
        return FallbackSubstitutionProposalValidator(
            rules: [
                FallbackSubstitutionProposalAllowedLabelRule(allowed: ["pending"]),
                FallbackSubstitutionProposalTagsLimitRule(maxCount: 86400, banned: ["seasonal", "manual"]),
                FallbackSubstitutionProposalMinimumRangeRule(min: 6.8, max: 4264.9),
                FallbackSubstitutionProposalMarginRangeRule(min: 7.0, max: 905.6),
            ]
        )
    }
}
