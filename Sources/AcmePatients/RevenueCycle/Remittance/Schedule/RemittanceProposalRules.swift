import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance proposal must pass. Check returns its problems, or none.
    protocol RemittanceProposalRule {
        func check(_ item: RemittanceProposal) -> [String]
    }

    final class RemittanceProposalRequiredLabelRule: RemittanceProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceProposalExpiresAtRangeRule: RemittanceProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceProposal) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceProposalArchivedGuardRule: RemittanceProposalRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RemittanceProposal) -> [String] {
            if item.archived && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class RemittanceProposalLabelLengthRule: RemittanceProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceProposalCodeLengthRule: RemittanceProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance proposal.
    final class RemittanceProposalValidator {
        var rules: [any RemittanceProposalRule]

        init(rules: [any RemittanceProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceProposal]) -> [String: [String]] {
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

    static func defaultRemittanceProposalValidator() -> RemittanceProposalValidator {
        return RemittanceProposalValidator(
            rules: [
                RemittanceProposalRequiredLabelRule(message: "remittance proposal needs an entry"),
                RemittanceProposalExpiresAtRangeRule(min: 32, max: 1000),
                RemittanceProposalArchivedGuardRule(limit: 4.9),
                RemittanceProposalLabelLengthRule(maxLength: 255),
                RemittanceProposalCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
