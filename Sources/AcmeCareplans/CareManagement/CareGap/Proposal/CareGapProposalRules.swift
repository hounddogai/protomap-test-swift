import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap proposal must pass. Check returns its problems, or none.
    protocol CareGapProposalRule {
        func check(_ item: CareGapProposal) -> [String]
    }

    final class CareGapProposalCodeLengthRule: CareGapProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapProposalLabelLengthRule: CareGapProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapProposalRequiredCodeRule: CareGapProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapProposalAttemptsRangeRule: CareGapProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapProposal) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care gap proposal.
    final class CareGapProposalValidator {
        var rules: [any CareGapProposalRule]

        init(rules: [any CareGapProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapProposal) -> [String] {
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

        func requireValid(_ item: CareGapProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapProposal]) -> [String: [String]] {
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

    static func defaultCareGapProposalValidator() -> CareGapProposalValidator {
        return CareGapProposalValidator(
            rules: [
                CareGapProposalCodeLengthRule(maxLength: 64),
                CareGapProposalLabelLengthRule(maxLength: 255),
                CareGapProposalRequiredCodeRule(message: "care gap proposal needs this field"),
                CareGapProposalAttemptsRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
