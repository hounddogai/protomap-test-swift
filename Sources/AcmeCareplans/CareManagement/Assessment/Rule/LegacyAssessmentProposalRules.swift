import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy assessment proposal must pass. Check returns its problems, or none.
    protocol LegacyAssessmentProposalRule {
        func check(_ item: LegacyAssessmentProposal) -> [String]
    }

    final class LegacyAssessmentProposalDiscountRangeRule: LegacyAssessmentProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAssessmentProposal) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyAssessmentProposalPinnedGuardRule: LegacyAssessmentProposalRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LegacyAssessmentProposal) -> [String] {
            if item.pinned && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class LegacyAssessmentProposalRequiredCodeRule: LegacyAssessmentProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAssessmentProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAssessmentProposalCurrencyLengthRule: LegacyAssessmentProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAssessmentProposal) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAssessmentProposalCodePrefixRule: LegacyAssessmentProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyAssessmentProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyAssessmentProposalRequiredSpecialtyRule: LegacyAssessmentProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAssessmentProposal) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy assessment proposal.
    final class LegacyAssessmentProposalValidator {
        var rules: [any LegacyAssessmentProposalRule]

        init(rules: [any LegacyAssessmentProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAssessmentProposal) -> [String] {
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

        func requireValid(_ item: LegacyAssessmentProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAssessmentProposal]) -> [String: [String]] {
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

    static func defaultLegacyAssessmentProposalValidator() -> LegacyAssessmentProposalValidator {
        return LegacyAssessmentProposalValidator(
            rules: [
                LegacyAssessmentProposalDiscountRangeRule(min: 0.7, max: 861.3),
                LegacyAssessmentProposalPinnedGuardRule(limit: 8.0),
                LegacyAssessmentProposalRequiredCodeRule(message: "legacy assessment proposal needs an entry"),
                LegacyAssessmentProposalCurrencyLengthRule(maxLength: 16),
                LegacyAssessmentProposalCodePrefixRule(prefix: "REF"),
                LegacyAssessmentProposalRequiredSpecialtyRule(message: "legacy assessment proposal needs a value"),
            ]
        )
    }
}
