import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime proposal must pass. Check returns its problems, or none.
    protocol OvertimeProposalRule {
        func check(_ item: OvertimeProposal) -> [String]
    }

    final class OvertimeProposalRequiredPayerRule: OvertimeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeProposal) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeProposalRequiredCodeRule: OvertimeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeProposalPayerLengthRule: OvertimeProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeProposal) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeProposalOwnerIDLengthRule: OvertimeProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeProposal) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeProposalRequiredNameRule: OvertimeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeProposalBatchSizeRangeRule: OvertimeProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeProposal) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime proposal.
    final class OvertimeProposalValidator {
        var rules: [any OvertimeProposalRule]

        init(rules: [any OvertimeProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeProposal]) -> [String: [String]] {
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

    static func defaultOvertimeProposalValidator() -> OvertimeProposalValidator {
        return OvertimeProposalValidator(
            rules: [
                OvertimeProposalRequiredPayerRule(message: "overtime proposal needs an entry"),
                OvertimeProposalRequiredCodeRule(message: "overtime proposal needs an entry"),
                OvertimeProposalPayerLengthRule(maxLength: 80),
                OvertimeProposalOwnerIDLengthRule(maxLength: 16),
                OvertimeProposalRequiredNameRule(message: "overtime proposal needs this field"),
                OvertimeProposalBatchSizeRangeRule(min: 1000, max: 86400),
            ]
        )
    }
}
