import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal skill mix proposal must pass. Check returns its problems, or none.
    protocol SeasonalSkillMixProposalRule {
        func check(_ item: SeasonalSkillMixProposal) -> [String]
    }

    final class SeasonalSkillMixProposalCapacityRangeRule: SeasonalSkillMixProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSkillMixProposal) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalSkillMixProposalRefillsRangeRule: SeasonalSkillMixProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSkillMixProposal) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalSkillMixProposalRequiredNameRule: SeasonalSkillMixProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSkillMixProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalSkillMixProposalBudgetRangeRule: SeasonalSkillMixProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSkillMixProposal) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalSkillMixProposalAllowedCodeRule: SeasonalSkillMixProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalSkillMixProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class SeasonalSkillMixProposalNameLengthRule: SeasonalSkillMixProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSkillMixProposal) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal skill mix proposal.
    final class SeasonalSkillMixProposalValidator {
        var rules: [any SeasonalSkillMixProposalRule]

        init(rules: [any SeasonalSkillMixProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSkillMixProposal) -> [String] {
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

        func requireValid(_ item: SeasonalSkillMixProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSkillMixProposal]) -> [String: [String]] {
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

    static func defaultSeasonalSkillMixProposalValidator() -> SeasonalSkillMixProposalValidator {
        return SeasonalSkillMixProposalValidator(
            rules: [
                SeasonalSkillMixProposalCapacityRangeRule(min: 80, max: 80),
                SeasonalSkillMixProposalRefillsRangeRule(min: 32, max: 120),
                SeasonalSkillMixProposalRequiredNameRule(message: "seasonal skill mix proposal needs an entry"),
                SeasonalSkillMixProposalBudgetRangeRule(min: 1.1, max: 1367.7),
                SeasonalSkillMixProposalAllowedCodeRule(allowed: ["adaptive"]),
                SeasonalSkillMixProposalNameLengthRule(maxLength: 32),
            ]
        )
    }
}
