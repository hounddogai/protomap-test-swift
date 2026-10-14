import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense proposal must pass. Check returns its problems, or none.
    protocol DispenseProposalRule {
        func check(_ item: DispenseProposal) -> [String]
    }

    final class DispenseProposalNameLengthRule: DispenseProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseProposal) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseProposalRegionLengthRule: DispenseProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseProposal) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseProposalCodePrefixRule: DispenseProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DispenseProposalAllowedCountryRule: DispenseProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense proposal.
    final class DispenseProposalValidator {
        var rules: [any DispenseProposalRule]

        init(rules: [any DispenseProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseProposal]) -> [String: [String]] {
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

    static func defaultDispenseProposalValidator() -> DispenseProposalValidator {
        return DispenseProposalValidator(
            rules: [
                DispenseProposalNameLengthRule(maxLength: 64),
                DispenseProposalRegionLengthRule(maxLength: 1000),
                DispenseProposalCodePrefixRule(prefix: "ACM"),
                DispenseProposalAllowedCountryRule(allowed: ["seasonal", "seasonal"]),
            ]
        )
    }
}
