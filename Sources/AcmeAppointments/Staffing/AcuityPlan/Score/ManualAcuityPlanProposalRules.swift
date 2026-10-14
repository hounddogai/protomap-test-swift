import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a manual acuity plan proposal must pass. Check returns its problems, or none.
    protocol ManualAcuityPlanProposalRule {
        func check(_ item: ManualAcuityPlanProposal) -> [String]
    }

    final class ManualAcuityPlanProposalCodeLengthRule: ManualAcuityPlanProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualAcuityPlanProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualAcuityPlanProposalRequiredCodeRule: ManualAcuityPlanProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAcuityPlanProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualAcuityPlanProposalLocaleLengthRule: ManualAcuityPlanProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualAcuityPlanProposal) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual acuity plan proposal.
    final class ManualAcuityPlanProposalValidator {
        var rules: [any ManualAcuityPlanProposalRule]

        init(rules: [any ManualAcuityPlanProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualAcuityPlanProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualAcuityPlanProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualAcuityPlanProposal]) -> [String: [String]] {
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

    static func defaultManualAcuityPlanProposalValidator() -> ManualAcuityPlanProposalValidator {
        return ManualAcuityPlanProposalValidator(
            rules: [
                ManualAcuityPlanProposalCodeLengthRule(maxLength: 1000),
                ManualAcuityPlanProposalRequiredCodeRule(message: "manual acuity plan proposal needs a value"),
                ManualAcuityPlanProposalLocaleLengthRule(maxLength: 255),
            ]
        )
    }
}
