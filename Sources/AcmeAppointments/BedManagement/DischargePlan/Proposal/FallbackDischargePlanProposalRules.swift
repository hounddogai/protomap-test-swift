import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback discharge plan proposal must pass. Check returns its problems, or none.
    protocol FallbackDischargePlanProposalRule {
        func check(_ item: FallbackDischargePlanProposal) -> [String]
    }

    final class FallbackDischargePlanProposalRequiredDescriptionRule: FallbackDischargePlanProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDischargePlanProposal) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDischargePlanProposalCodeLengthRule: FallbackDischargePlanProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDischargePlanProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDischargePlanProposalRequiredCodeRule: FallbackDischargePlanProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDischargePlanProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback discharge plan proposal.
    final class FallbackDischargePlanProposalValidator {
        var rules: [any FallbackDischargePlanProposalRule]

        init(rules: [any FallbackDischargePlanProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDischargePlanProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackDischargePlanProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDischargePlanProposal]) -> [String: [String]] {
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

    static func defaultFallbackDischargePlanProposalValidator() -> FallbackDischargePlanProposalValidator {
        return FallbackDischargePlanProposalValidator(
            rules: [
                FallbackDischargePlanProposalRequiredDescriptionRule(
                    message: "fallback discharge plan proposal needs this field"
                ),
                FallbackDischargePlanProposalCodeLengthRule(maxLength: 86400),
                FallbackDischargePlanProposalRequiredCodeRule(
                    message: "fallback discharge plan proposal needs this field"
                ),
            ]
        )
    }
}
