import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered overtime proposal must pass. Check returns its problems, or none.
    protocol TieredOvertimeProposalRule {
        func check(_ item: TieredOvertimeProposal) -> [String]
    }

    final class TieredOvertimeProposalRequiredCategoryRule: TieredOvertimeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOvertimeProposal) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredOvertimeProposalCodePrefixRule: TieredOvertimeProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredOvertimeProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredOvertimeProposalAllowedNameRule: TieredOvertimeProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredOvertimeProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class TieredOvertimeProposalRequiredCodeRule: TieredOvertimeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOvertimeProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered overtime proposal.
    final class TieredOvertimeProposalValidator {
        var rules: [any TieredOvertimeProposalRule]

        init(rules: [any TieredOvertimeProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredOvertimeProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredOvertimeProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredOvertimeProposal]) -> [String: [String]] {
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

    static func defaultTieredOvertimeProposalValidator() -> TieredOvertimeProposalValidator {
        return TieredOvertimeProposalValidator(
            rules: [
                TieredOvertimeProposalRequiredCategoryRule(message: "tiered overtime proposal needs an entry"),
                TieredOvertimeProposalCodePrefixRule(prefix: "ACM"),
                TieredOvertimeProposalAllowedNameRule(allowed: ["legacy"]),
                TieredOvertimeProposalRequiredCodeRule(message: "tiered overtime proposal needs a value"),
            ]
        )
    }
}
