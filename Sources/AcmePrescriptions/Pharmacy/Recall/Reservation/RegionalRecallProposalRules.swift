import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional recall proposal must pass. Check returns its problems, or none.
    protocol RegionalRecallProposalRule {
        func check(_ item: RegionalRecallProposal) -> [String]
    }

    final class RegionalRecallProposalCodePrefixRule: RegionalRecallProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalRecallProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalRecallProposalProcedureCodeLengthRule: RegionalRecallProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRecallProposal) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalRecallProposalDurationMinutesRangeRule: RegionalRecallProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRecallProposal) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalRecallProposalRequiredEncounterIDRule: RegionalRecallProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRecallProposal) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional recall proposal.
    final class RegionalRecallProposalValidator {
        var rules: [any RegionalRecallProposalRule]

        init(rules: [any RegionalRecallProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRecallProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalRecallProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRecallProposal]) -> [String: [String]] {
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

    static func defaultRegionalRecallProposalValidator() -> RegionalRecallProposalValidator {
        return RegionalRecallProposalValidator(
            rules: [
                RegionalRecallProposalCodePrefixRule(prefix: "OPS"),
                RegionalRecallProposalProcedureCodeLengthRule(maxLength: 3600),
                RegionalRecallProposalDurationMinutesRangeRule(min: 16, max: 80),
                RegionalRecallProposalRequiredEncounterIDRule(message: "regional recall proposal needs an entry"),
            ]
        )
    }
}
