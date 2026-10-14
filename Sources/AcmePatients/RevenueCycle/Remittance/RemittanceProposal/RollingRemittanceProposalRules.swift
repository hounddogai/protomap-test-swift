import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling remittance proposal must pass. Check returns its problems, or none.
    protocol RollingRemittanceProposalRule {
        func check(_ item: RollingRemittanceProposal) -> [String]
    }

    final class RollingRemittanceProposalAllowedTitleRule: RollingRemittanceProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingRemittanceProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class RollingRemittanceProposalPatientRefLengthRule: RollingRemittanceProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRemittanceProposal) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingRemittanceProposalRequiredUnitRule: RollingRemittanceProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRemittanceProposal) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling remittance proposal.
    final class RollingRemittanceProposalValidator {
        var rules: [any RollingRemittanceProposalRule]

        init(rules: [any RollingRemittanceProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRemittanceProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingRemittanceProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRemittanceProposal]) -> [String: [String]] {
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

    static func defaultRollingRemittanceProposalValidator() -> RollingRemittanceProposalValidator {
        return RollingRemittanceProposalValidator(
            rules: [
                RollingRemittanceProposalAllowedTitleRule(allowed: ["capped"]),
                RollingRemittanceProposalPatientRefLengthRule(maxLength: 255),
                RollingRemittanceProposalRequiredUnitRule(message: "rolling remittance proposal needs this field"),
            ]
        )
    }
}
