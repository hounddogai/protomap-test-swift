import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy accession proposal must pass. Check returns its problems, or none.
    protocol LegacyAccessionProposalRule {
        func check(_ item: LegacyAccessionProposal) -> [String]
    }

    final class LegacyAccessionProposalLabelLengthRule: LegacyAccessionProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAccessionProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAccessionProposalFloorValueRangeRule: LegacyAccessionProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAccessionProposal) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyAccessionProposalNameLengthRule: LegacyAccessionProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAccessionProposal) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAccessionProposalCodePrefixRule: LegacyAccessionProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyAccessionProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy accession proposal.
    final class LegacyAccessionProposalValidator {
        var rules: [any LegacyAccessionProposalRule]

        init(rules: [any LegacyAccessionProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAccessionProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyAccessionProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAccessionProposal]) -> [String: [String]] {
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

    static func defaultLegacyAccessionProposalValidator() -> LegacyAccessionProposalValidator {
        return LegacyAccessionProposalValidator(
            rules: [
                LegacyAccessionProposalLabelLengthRule(maxLength: 3600),
                LegacyAccessionProposalFloorValueRangeRule(min: 8.4, max: 1538.0),
                LegacyAccessionProposalNameLengthRule(maxLength: 80),
                LegacyAccessionProposalCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
