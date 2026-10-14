import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority proposal must pass. Check returns its problems, or none.
    protocol PriorityProposalRule {
        func check(_ item: PriorityProposal) -> [String]
    }

    final class PriorityProposalRequiredNameRule: PriorityProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityProposalLimitRangeRule: PriorityProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityProposal) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityProposalRequiredCodeRule: PriorityProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityProposalAllowedCodeRule: PriorityProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PriorityProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class PriorityProposalAcuityRangeRule: PriorityProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityProposal) -> [String] {
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

    /// Runs every rule of a priority proposal.
    final class PriorityProposalValidator {
        var rules: [any PriorityProposalRule]

        init(rules: [any PriorityProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityProposal) -> [String] {
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

        func requireValid(_ item: PriorityProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityProposal]) -> [String: [String]] {
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

    static func defaultPriorityProposalValidator() -> PriorityProposalValidator {
        return PriorityProposalValidator(
            rules: [
                PriorityProposalRequiredNameRule(message: "priority proposal needs this field"),
                PriorityProposalLimitRangeRule(min: 1000, max: 3600),
                PriorityProposalRequiredCodeRule(message: "priority proposal needs a value"),
                PriorityProposalAllowedCodeRule(allowed: ["lenient", "strict", "primary"]),
                PriorityProposalAcuityRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
