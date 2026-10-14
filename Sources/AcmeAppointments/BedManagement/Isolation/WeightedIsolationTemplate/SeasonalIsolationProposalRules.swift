import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a seasonal isolation proposal must pass. Check returns its problems, or none.
    protocol SeasonalIsolationProposalRule {
        func check(_ item: SeasonalIsolationProposal) -> [String]
    }

    final class SeasonalIsolationProposalAcuityRangeRule: SeasonalIsolationProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalIsolationProposal) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalIsolationProposalRevisionRangeRule: SeasonalIsolationProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalIsolationProposal) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalIsolationProposalAllowedTitleRule: SeasonalIsolationProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalIsolationProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal isolation proposal.
    final class SeasonalIsolationProposalValidator {
        var rules: [any SeasonalIsolationProposalRule]

        init(rules: [any SeasonalIsolationProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalIsolationProposal) -> [String] {
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

        func requireValid(_ item: SeasonalIsolationProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalIsolationProposal]) -> [String: [String]] {
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

    static func defaultSeasonalIsolationProposalValidator() -> SeasonalIsolationProposalValidator {
        return SeasonalIsolationProposalValidator(
            rules: [
                SeasonalIsolationProposalAcuityRangeRule(min: 120, max: 86400),
                SeasonalIsolationProposalRevisionRangeRule(min: 3600, max: 3600),
                SeasonalIsolationProposalAllowedTitleRule(allowed: ["lenient", "tiered", "legacy"]),
            ]
        )
    }
}
