import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending read proposal must pass. Check returns its problems, or none.
    protocol PendingReadProposalRule {
        func check(_ item: PendingReadProposal) -> [String]
    }

    final class PendingReadProposalCodePrefixRule: PendingReadProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingReadProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingReadProposalVisibleGuardRule: PendingReadProposalRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PendingReadProposal) -> [String] {
            if item.visible && (item.batchSize > limit) {
                return ["batch size \(item.batchSize) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class PendingReadProposalRequiredLocaleRule: PendingReadProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReadProposal) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReadProposalAllowedCategoryRule: PendingReadProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingReadProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is not allowed"]
            }
            return []
        }
    }

    final class PendingReadProposalRequiredChecksumRule: PendingReadProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReadProposal) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending read proposal.
    final class PendingReadProposalValidator {
        var rules: [any PendingReadProposalRule]

        init(rules: [any PendingReadProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingReadProposal) -> [String] {
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

        func requireValid(_ item: PendingReadProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingReadProposal]) -> [String: [String]] {
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

    static func defaultPendingReadProposalValidator() -> PendingReadProposalValidator {
        return PendingReadProposalValidator(
            rules: [
                PendingReadProposalCodePrefixRule(prefix: "Q"),
                PendingReadProposalVisibleGuardRule(limit: 16),
                PendingReadProposalRequiredLocaleRule(message: "pending read proposal needs this field"),
                PendingReadProposalAllowedCategoryRule(allowed: []),
                PendingReadProposalRequiredChecksumRule(message: "pending read proposal needs an entry"),
            ]
        )
    }
}
