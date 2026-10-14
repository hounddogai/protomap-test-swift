import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a lenient overtime proposal must pass. Check returns its problems, or none.
    protocol LenientOvertimeProposalRule {
        func check(_ item: LenientOvertimeProposal) -> [String]
    }

    final class LenientOvertimeProposalLabelLengthRule: LenientOvertimeProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOvertimeProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientOvertimeProposalRequiredCodeRule: LenientOvertimeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOvertimeProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientOvertimeProposalAcuityRangeRule: LenientOvertimeProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOvertimeProposal) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientOvertimeProposalRequiredLabelRule: LenientOvertimeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOvertimeProposal) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientOvertimeProposalAllowedLabelRule: LenientOvertimeProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientOvertimeProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class LenientOvertimeProposalAttemptsRangeRule: LenientOvertimeProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOvertimeProposal) -> [String] {
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

    /// Runs every rule of a lenient overtime proposal.
    final class LenientOvertimeProposalValidator {
        var rules: [any LenientOvertimeProposalRule]

        init(rules: [any LenientOvertimeProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientOvertimeProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientOvertimeProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientOvertimeProposal]) -> [String: [String]] {
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

    static func defaultLenientOvertimeProposalValidator() -> LenientOvertimeProposalValidator {
        return LenientOvertimeProposalValidator(
            rules: [
                LenientOvertimeProposalLabelLengthRule(maxLength: 120),
                LenientOvertimeProposalRequiredCodeRule(message: "lenient overtime proposal needs this field"),
                LenientOvertimeProposalAcuityRangeRule(min: 80, max: 1000),
                LenientOvertimeProposalRequiredLabelRule(message: "lenient overtime proposal needs an entry"),
                LenientOvertimeProposalAllowedLabelRule(allowed: ["capped", "pending"]),
                LenientOvertimeProposalAttemptsRangeRule(min: 32, max: 120),
            ]
        )
    }
}
