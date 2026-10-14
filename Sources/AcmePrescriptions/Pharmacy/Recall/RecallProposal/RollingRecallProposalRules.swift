import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling recall proposal must pass. Check returns its problems, or none.
    protocol RollingRecallProposalRule {
        func check(_ item: RollingRecallProposal) -> [String]
    }

    final class RollingRecallProposalPinnedGuardRule: RollingRecallProposalRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RollingRecallProposal) -> [String] {
            if item.pinned && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class RollingRecallProposalAllowedEncounterIDRule: RollingRecallProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingRecallProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is above maximum"]
            }
            return []
        }
    }

    final class RollingRecallProposalRequiredLabelRule: RollingRecallProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRecallProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingRecallProposalProcedureCodeLengthRule: RollingRecallProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRecallProposal) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingRecallProposalRatioRangeRule: RollingRecallProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingRecallProposal) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling recall proposal.
    final class RollingRecallProposalValidator {
        var rules: [any RollingRecallProposalRule]

        init(rules: [any RollingRecallProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRecallProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingRecallProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRecallProposal]) -> [String: [String]] {
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

    static func defaultRollingRecallProposalValidator() -> RollingRecallProposalValidator {
        return RollingRecallProposalValidator(
            rules: [
                RollingRecallProposalPinnedGuardRule(limit: 5.4),
                RollingRecallProposalAllowedEncounterIDRule(allowed: ["default"]),
                RollingRecallProposalRequiredLabelRule(message: "rolling recall proposal needs an entry"),
                RollingRecallProposalProcedureCodeLengthRule(maxLength: 32),
                RollingRecallProposalRatioRangeRule(min: 4.2, max: 1849.6),
            ]
        )
    }
}
