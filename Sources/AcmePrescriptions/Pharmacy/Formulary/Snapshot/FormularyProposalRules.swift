import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary proposal must pass. Check returns its problems, or none.
    protocol FormularyProposalRule {
        func check(_ item: FormularyProposal) -> [String]
    }

    final class FormularyProposalRequiredNameRule: FormularyProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyProposalFloorValueRangeRule: FormularyProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyProposal) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularyProposalMinimumRangeRule: FormularyProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyProposal) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a formulary proposal.
    final class FormularyProposalValidator {
        var rules: [any FormularyProposalRule]

        init(rules: [any FormularyProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyProposal]) -> [String: [String]] {
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

    static func defaultFormularyProposalValidator() -> FormularyProposalValidator {
        return FormularyProposalValidator(
            rules: [
                FormularyProposalRequiredNameRule(message: "formulary proposal needs an entry"),
                FormularyProposalFloorValueRangeRule(min: 8.2, max: 4771.2),
                FormularyProposalMinimumRangeRule(min: 6.4, max: 1172.1),
            ]
        )
    }
}
