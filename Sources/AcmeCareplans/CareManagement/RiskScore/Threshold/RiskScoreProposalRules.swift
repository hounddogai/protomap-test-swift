import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score proposal must pass. Check returns its problems, or none.
    protocol RiskScoreProposalRule {
        func check(_ item: RiskScoreProposal) -> [String]
    }

    final class RiskScoreProposalClinicianIDLengthRule: RiskScoreProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreProposal) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreProposalRequiredNameRule: RiskScoreProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreProposalCurrencyLengthRule: RiskScoreProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreProposal) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreProposalRatioRangeRule: RiskScoreProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreProposal) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score proposal.
    final class RiskScoreProposalValidator {
        var rules: [any RiskScoreProposalRule]

        init(rules: [any RiskScoreProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreProposal) -> [String] {
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

        func requireValid(_ item: RiskScoreProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreProposal]) -> [String: [String]] {
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

    static func defaultRiskScoreProposalValidator() -> RiskScoreProposalValidator {
        return RiskScoreProposalValidator(
            rules: [
                RiskScoreProposalClinicianIDLengthRule(maxLength: 80),
                RiskScoreProposalRequiredNameRule(message: "risk score proposal needs an entry"),
                RiskScoreProposalCurrencyLengthRule(maxLength: 64),
                RiskScoreProposalRatioRangeRule(min: 5.2, max: 4628.1),
            ]
        )
    }
}
