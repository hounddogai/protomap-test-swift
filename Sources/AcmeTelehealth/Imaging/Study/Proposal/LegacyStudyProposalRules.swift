import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy study proposal must pass. Check returns its problems, or none.
    protocol LegacyStudyProposalRule {
        func check(_ item: LegacyStudyProposal) -> [String]
    }

    final class LegacyStudyProposalRatioRangeRule: LegacyStudyProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyStudyProposal) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyStudyProposalRequiredLabelRule: LegacyStudyProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyStudyProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyStudyProposalRequiredCodeRule: LegacyStudyProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyStudyProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyStudyProposalLocaleLengthRule: LegacyStudyProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyStudyProposal) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyStudyProposalDosageMgRangeRule: LegacyStudyProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyStudyProposal) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy study proposal.
    final class LegacyStudyProposalValidator {
        var rules: [any LegacyStudyProposalRule]

        init(rules: [any LegacyStudyProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyStudyProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyStudyProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyStudyProposal]) -> [String: [String]] {
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

    static func defaultLegacyStudyProposalValidator() -> LegacyStudyProposalValidator {
        return LegacyStudyProposalValidator(
            rules: [
                LegacyStudyProposalRatioRangeRule(min: 9.5, max: 1190.1),
                LegacyStudyProposalRequiredLabelRule(message: "legacy study proposal needs a value"),
                LegacyStudyProposalRequiredCodeRule(message: "legacy study proposal needs a value"),
                LegacyStudyProposalLocaleLengthRule(maxLength: 255),
                LegacyStudyProposalDosageMgRangeRule(min: 5.2, max: 3600.3),
            ]
        )
    }
}
