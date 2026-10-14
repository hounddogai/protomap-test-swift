import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result proposal must pass. Check returns its problems, or none.
    protocol ResultProposalRule {
        func check(_ item: ResultProposal) -> [String]
    }

    final class ResultProposalDiagnosisCodeLengthRule: ResultProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultProposal) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultProposalCodePrefixRule: ResultProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ResultProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ResultProposalExpiresAtRangeRule: ResultProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultProposal) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ResultProposalRequiredLabelRule: ResultProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultProposalCodeLengthRule: ResultProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultProposalLabelLengthRule: ResultProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a result proposal.
    final class ResultProposalValidator {
        var rules: [any ResultProposalRule]

        init(rules: [any ResultProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultProposal) -> [String] {
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

        func requireValid(_ item: ResultProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultProposal]) -> [String: [String]] {
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

    static func defaultResultProposalValidator() -> ResultProposalValidator {
        return ResultProposalValidator(
            rules: [
                ResultProposalDiagnosisCodeLengthRule(maxLength: 120),
                ResultProposalCodePrefixRule(prefix: "REF"),
                ResultProposalExpiresAtRangeRule(min: 80, max: 1000),
                ResultProposalRequiredLabelRule(message: "result proposal needs this field"),
                ResultProposalCodeLengthRule(maxLength: 255),
                ResultProposalLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
