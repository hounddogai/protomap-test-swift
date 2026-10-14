import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default transfer proposal must pass. Check returns its problems, or none.
    protocol DefaultTransferProposalRule {
        func check(_ item: DefaultTransferProposal) -> [String]
    }

    final class DefaultTransferProposalVersionRangeRule: DefaultTransferProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultTransferProposal) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultTransferProposalWeightRangeRule: DefaultTransferProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultTransferProposal) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultTransferProposalCodePrefixRule: DefaultTransferProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultTransferProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultTransferProposalAllowedLocaleRule: DefaultTransferProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultTransferProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is unknown"]
            }
            return []
        }
    }

    final class DefaultTransferProposalRequiredLabelRule: DefaultTransferProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultTransferProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultTransferProposalContactEmailLengthRule: DefaultTransferProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultTransferProposal) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default transfer proposal.
    final class DefaultTransferProposalValidator {
        var rules: [any DefaultTransferProposalRule]

        init(rules: [any DefaultTransferProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultTransferProposal) -> [String] {
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

        func requireValid(_ item: DefaultTransferProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultTransferProposal]) -> [String: [String]] {
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

    static func defaultDefaultTransferProposalValidator() -> DefaultTransferProposalValidator {
        return DefaultTransferProposalValidator(
            rules: [
                DefaultTransferProposalVersionRangeRule(min: 255, max: 86400),
                DefaultTransferProposalWeightRangeRule(min: 0.9, max: 4352.4),
                DefaultTransferProposalCodePrefixRule(prefix: "X"),
                DefaultTransferProposalAllowedLocaleRule(allowed: ["rolling", "fallback"]),
                DefaultTransferProposalRequiredLabelRule(message: "default transfer proposal needs an entry"),
                DefaultTransferProposalContactEmailLengthRule(maxLength: 80),
            ]
        )
    }
}
