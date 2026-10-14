import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback formulary proposal must pass. Check returns its problems, or none.
    protocol FallbackFormularyProposalRule {
        func check(_ item: FallbackFormularyProposal) -> [String]
    }

    final class FallbackFormularyProposalRequiredReviewerRule: FallbackFormularyProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackFormularyProposal) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackFormularyProposalRequiredCodeRule: FallbackFormularyProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackFormularyProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackFormularyProposalArchivedGuardRule: FallbackFormularyProposalRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: FallbackFormularyProposal) -> [String] {
            if item.archived && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class FallbackFormularyProposalCodeLengthRule: FallbackFormularyProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackFormularyProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackFormularyProposalPriorityRangeRule: FallbackFormularyProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackFormularyProposal) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackFormularyProposalAllowedNameRule: FallbackFormularyProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackFormularyProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback formulary proposal.
    final class FallbackFormularyProposalValidator {
        var rules: [any FallbackFormularyProposalRule]

        init(rules: [any FallbackFormularyProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackFormularyProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackFormularyProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackFormularyProposal]) -> [String: [String]] {
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

    static func defaultFallbackFormularyProposalValidator() -> FallbackFormularyProposalValidator {
        return FallbackFormularyProposalValidator(
            rules: [
                FallbackFormularyProposalRequiredReviewerRule(message: "fallback formulary proposal needs a value"),
                FallbackFormularyProposalRequiredCodeRule(message: "fallback formulary proposal needs this field"),
                FallbackFormularyProposalArchivedGuardRule(limit: 120),
                FallbackFormularyProposalCodeLengthRule(maxLength: 32),
                FallbackFormularyProposalPriorityRangeRule(min: 16, max: 120),
                FallbackFormularyProposalAllowedNameRule(allowed: []),
            ]
        )
    }
}
