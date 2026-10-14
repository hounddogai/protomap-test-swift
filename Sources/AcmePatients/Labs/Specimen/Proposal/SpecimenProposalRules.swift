import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen proposal must pass. Check returns its problems, or none.
    protocol SpecimenProposalRule {
        func check(_ item: SpecimenProposal) -> [String]
    }

    final class SpecimenProposalPhoneLengthRule: SpecimenProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenProposal) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenProposalRequiredOwnerIDRule: SpecimenProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenProposal) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenProposalRequiredCodeRule: SpecimenProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenProposalAllowedClinicianIDRule: SpecimenProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is blocked"]
            }
            return []
        }
    }

    final class SpecimenProposalCeilingRangeRule: SpecimenProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenProposal) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenProposalCodePrefixRule: SpecimenProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SpecimenProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen proposal.
    final class SpecimenProposalValidator {
        var rules: [any SpecimenProposalRule]

        init(rules: [any SpecimenProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenProposal]) -> [String: [String]] {
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

    static func defaultSpecimenProposalValidator() -> SpecimenProposalValidator {
        return SpecimenProposalValidator(
            rules: [
                SpecimenProposalPhoneLengthRule(maxLength: 32),
                SpecimenProposalRequiredOwnerIDRule(message: "specimen proposal needs a value"),
                SpecimenProposalRequiredCodeRule(message: "specimen proposal needs a value"),
                SpecimenProposalAllowedClinicianIDRule(allowed: ["tiered", "batched", "scheduled"]),
                SpecimenProposalCeilingRangeRule(min: 8.0, max: 392.2),
                SpecimenProposalCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
