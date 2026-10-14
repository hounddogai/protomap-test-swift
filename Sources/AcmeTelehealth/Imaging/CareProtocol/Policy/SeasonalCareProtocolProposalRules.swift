import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal care protocol proposal must pass. Check returns its problems, or none.
    protocol SeasonalCareProtocolProposalRule {
        func check(_ item: SeasonalCareProtocolProposal) -> [String]
    }

    final class SeasonalCareProtocolProposalAllowedCodeRule: SeasonalCareProtocolProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalCareProtocolProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class SeasonalCareProtocolProposalCreatedAtRangeRule: SeasonalCareProtocolProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareProtocolProposal) -> [String] {
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

    final class SeasonalCareProtocolProposalVisitMinutesRangeRule: SeasonalCareProtocolProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareProtocolProposal) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal care protocol proposal.
    final class SeasonalCareProtocolProposalValidator {
        var rules: [any SeasonalCareProtocolProposalRule]

        init(rules: [any SeasonalCareProtocolProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCareProtocolProposal) -> [String] {
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

        func requireValid(_ item: SeasonalCareProtocolProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCareProtocolProposal]) -> [String: [String]] {
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

    static func defaultSeasonalCareProtocolProposalValidator() -> SeasonalCareProtocolProposalValidator {
        return SeasonalCareProtocolProposalValidator(
            rules: [
                SeasonalCareProtocolProposalAllowedCodeRule(allowed: ["regional", "regional"]),
                SeasonalCareProtocolProposalCreatedAtRangeRule(min: 16, max: 255),
                SeasonalCareProtocolProposalVisitMinutesRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
