import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback reference range proposal must pass. Check returns its problems, or none.
    protocol FallbackReferenceRangeProposalRule {
        func check(_ item: FallbackReferenceRangeProposal) -> [String]
    }

    final class FallbackReferenceRangeProposalAllergyLengthRule: FallbackReferenceRangeProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackReferenceRangeProposal) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackReferenceRangeProposalAllowedDiagnosisCodeRule: FallbackReferenceRangeProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackReferenceRangeProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is too long"]
            }
            return []
        }
    }

    final class FallbackReferenceRangeProposalLimitRangeRule: FallbackReferenceRangeProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackReferenceRangeProposal) -> [String] {
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

    final class FallbackReferenceRangeProposalRequiredNameRule: FallbackReferenceRangeProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackReferenceRangeProposal) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackReferenceRangeProposalDiagnosisCodeLengthRule: FallbackReferenceRangeProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackReferenceRangeProposal) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback reference range proposal.
    final class FallbackReferenceRangeProposalValidator {
        var rules: [any FallbackReferenceRangeProposalRule]

        init(rules: [any FallbackReferenceRangeProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackReferenceRangeProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackReferenceRangeProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackReferenceRangeProposal]) -> [String: [String]] {
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

    static func defaultFallbackReferenceRangeProposalValidator() -> FallbackReferenceRangeProposalValidator {
        return FallbackReferenceRangeProposalValidator(
            rules: [
                FallbackReferenceRangeProposalAllergyLengthRule(maxLength: 1000),
                FallbackReferenceRangeProposalAllowedDiagnosisCodeRule(allowed: []),
                FallbackReferenceRangeProposalLimitRangeRule(min: 120, max: 86400),
                FallbackReferenceRangeProposalRequiredNameRule(
                    message: "fallback reference range proposal needs an entry"
                ),
                FallbackReferenceRangeProposalDiagnosisCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
