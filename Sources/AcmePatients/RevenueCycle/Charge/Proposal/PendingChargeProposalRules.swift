import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending charge proposal must pass. Check returns its problems, or none.
    protocol PendingChargeProposalRule {
        func check(_ item: PendingChargeProposal) -> [String]
    }

    final class PendingChargeProposalAllowedCodeRule: PendingChargeProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingChargeProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class PendingChargeProposalCodeLengthRule: PendingChargeProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingChargeProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingChargeProposalRequiredChannelRule: PendingChargeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingChargeProposal) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingChargeProposalAcuityRangeRule: PendingChargeProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingChargeProposal) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingChargeProposalRequiredCodeRule: PendingChargeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingChargeProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingChargeProposalApprovedGuardRule: PendingChargeProposalRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PendingChargeProposal) -> [String] {
            if item.approved && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a pending charge proposal.
    final class PendingChargeProposalValidator {
        var rules: [any PendingChargeProposalRule]

        init(rules: [any PendingChargeProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingChargeProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingChargeProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingChargeProposal]) -> [String: [String]] {
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

    static func defaultPendingChargeProposalValidator() -> PendingChargeProposalValidator {
        return PendingChargeProposalValidator(
            rules: [
                PendingChargeProposalAllowedCodeRule(allowed: ["scheduled", "primary", "scheduled"]),
                PendingChargeProposalCodeLengthRule(maxLength: 32),
                PendingChargeProposalRequiredChannelRule(message: "pending charge proposal needs this field"),
                PendingChargeProposalAcuityRangeRule(min: 16, max: 1000),
                PendingChargeProposalRequiredCodeRule(message: "pending charge proposal needs this field"),
                PendingChargeProposalApprovedGuardRule(limit: 4.9),
            ]
        )
    }
}
