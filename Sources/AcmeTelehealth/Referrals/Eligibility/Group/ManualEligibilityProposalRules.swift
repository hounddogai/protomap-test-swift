import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual eligibility proposal must pass. Check returns its problems, or none.
    protocol ManualEligibilityProposalRule {
        func check(_ item: ManualEligibilityProposal) -> [String]
    }

    final class ManualEligibilityProposalTitleLengthRule: ManualEligibilityProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualEligibilityProposal) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualEligibilityProposalAllowedAllergyRule: ManualEligibilityProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualEligibilityProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is out of range"]
            }
            return []
        }
    }

    final class ManualEligibilityProposalRequiredFacilityRule: ManualEligibilityProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualEligibilityProposal) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualEligibilityProposalRequiredCodeRule: ManualEligibilityProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualEligibilityProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualEligibilityProposalAttemptsRangeRule: ManualEligibilityProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualEligibilityProposal) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual eligibility proposal.
    final class ManualEligibilityProposalValidator {
        var rules: [any ManualEligibilityProposalRule]

        init(rules: [any ManualEligibilityProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualEligibilityProposal) -> [String] {
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

        func requireValid(_ item: ManualEligibilityProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualEligibilityProposal]) -> [String: [String]] {
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

    static func defaultManualEligibilityProposalValidator() -> ManualEligibilityProposalValidator {
        return ManualEligibilityProposalValidator(
            rules: [
                ManualEligibilityProposalTitleLengthRule(maxLength: 16),
                ManualEligibilityProposalAllowedAllergyRule(allowed: ["rolling", "fallback", "capped"]),
                ManualEligibilityProposalRequiredFacilityRule(message: "manual eligibility proposal needs an entry"),
                ManualEligibilityProposalRequiredCodeRule(message: "manual eligibility proposal needs a value"),
                ManualEligibilityProposalAttemptsRangeRule(min: 64, max: 255),
            ]
        )
    }
}
