import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending statement proposal must pass. Check returns its problems, or none.
    protocol PendingStatementProposalRule {
        func check(_ item: PendingStatementProposal) -> [String]
    }

    final class PendingStatementProposalCodeLengthRule: PendingStatementProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingStatementProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingStatementProposalRequiredNameRule: PendingStatementProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingStatementProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingStatementProposalCurrencyLengthRule: PendingStatementProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingStatementProposal) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingStatementProposalActiveGuardRule: PendingStatementProposalRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PendingStatementProposal) -> [String] {
            if item.active && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class PendingStatementProposalRequiredAllergyRule: PendingStatementProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingStatementProposal) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingStatementProposalVisitMinutesRangeRule: PendingStatementProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingStatementProposal) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a pending statement proposal.
    final class PendingStatementProposalValidator {
        var rules: [any PendingStatementProposalRule]

        init(rules: [any PendingStatementProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingStatementProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingStatementProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingStatementProposal]) -> [String: [String]] {
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

    static func defaultPendingStatementProposalValidator() -> PendingStatementProposalValidator {
        return PendingStatementProposalValidator(
            rules: [
                PendingStatementProposalCodeLengthRule(maxLength: 255),
                PendingStatementProposalRequiredNameRule(message: "pending statement proposal needs a value"),
                PendingStatementProposalCurrencyLengthRule(maxLength: 255),
                PendingStatementProposalActiveGuardRule(limit: 80),
                PendingStatementProposalRequiredAllergyRule(message: "pending statement proposal needs an entry"),
                PendingStatementProposalVisitMinutesRangeRule(min: 255, max: 3600),
            ]
        )
    }
}
