import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary discharge plan proposal must pass. Check returns its problems, or none.
    protocol PrimaryDischargePlanProposalRule {
        func check(_ item: PrimaryDischargePlanProposal) -> [String]
    }

    final class PrimaryDischargePlanProposalRequiredCodeRule: PrimaryDischargePlanProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDischargePlanProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDischargePlanProposalCreatedAtRangeRule: PrimaryDischargePlanProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDischargePlanProposal) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryDischargePlanProposalCodeLengthRule: PrimaryDischargePlanProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDischargePlanProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDischargePlanProposalLimitRangeRule: PrimaryDischargePlanProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDischargePlanProposal) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryDischargePlanProposalNameLengthRule: PrimaryDischargePlanProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDischargePlanProposal) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary discharge plan proposal.
    final class PrimaryDischargePlanProposalValidator {
        var rules: [any PrimaryDischargePlanProposalRule]

        init(rules: [any PrimaryDischargePlanProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryDischargePlanProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryDischargePlanProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryDischargePlanProposal]) -> [String: [String]] {
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

    static func defaultPrimaryDischargePlanProposalValidator() -> PrimaryDischargePlanProposalValidator {
        return PrimaryDischargePlanProposalValidator(
            rules: [
                PrimaryDischargePlanProposalRequiredCodeRule(
                    message: "primary discharge plan proposal needs this field"
                ),
                PrimaryDischargePlanProposalCreatedAtRangeRule(min: 32, max: 80),
                PrimaryDischargePlanProposalCodeLengthRule(maxLength: 3600),
                PrimaryDischargePlanProposalLimitRangeRule(min: 64, max: 64),
                PrimaryDischargePlanProposalNameLengthRule(maxLength: 120),
            ]
        )
    }
}
