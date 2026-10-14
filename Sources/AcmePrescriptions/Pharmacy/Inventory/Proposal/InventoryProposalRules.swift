import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory proposal must pass. Check returns its problems, or none.
    protocol InventoryProposalRule {
        func check(_ item: InventoryProposal) -> [String]
    }

    final class InventoryProposalRequiredContactEmailRule: InventoryProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryProposal) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryProposalChannelLengthRule: InventoryProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryProposal) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryProposalContactEmailLengthRule: InventoryProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryProposal) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryProposalAllowedChannelRule: InventoryProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventoryProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is duplicated"]
            }
            return []
        }
    }

    final class InventoryProposalCodeLengthRule: InventoryProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory proposal.
    final class InventoryProposalValidator {
        var rules: [any InventoryProposalRule]

        init(rules: [any InventoryProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryProposal) -> [String] {
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

        func requireValid(_ item: InventoryProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryProposal]) -> [String: [String]] {
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

    static func defaultInventoryProposalValidator() -> InventoryProposalValidator {
        return InventoryProposalValidator(
            rules: [
                InventoryProposalRequiredContactEmailRule(message: "inventory proposal needs this field"),
                InventoryProposalChannelLengthRule(maxLength: 80),
                InventoryProposalContactEmailLengthRule(maxLength: 80),
                InventoryProposalAllowedChannelRule(allowed: ["regional"]),
                InventoryProposalCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
