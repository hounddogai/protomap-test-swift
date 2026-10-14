import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive accession proposal must pass. Check returns its problems, or none.
    protocol AdaptiveAccessionProposalRule {
        func check(_ item: AdaptiveAccessionProposal) -> [String]
    }

    final class AdaptiveAccessionProposalRequiredFacilityRule: AdaptiveAccessionProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveAccessionProposal) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveAccessionProposalLimitRangeRule: AdaptiveAccessionProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAccessionProposal) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveAccessionProposalAmountRangeRule: AdaptiveAccessionProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAccessionProposal) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveAccessionProposalCodePrefixRule: AdaptiveAccessionProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveAccessionProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveAccessionProposalVersionRangeRule: AdaptiveAccessionProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAccessionProposal) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive accession proposal.
    final class AdaptiveAccessionProposalValidator {
        var rules: [any AdaptiveAccessionProposalRule]

        init(rules: [any AdaptiveAccessionProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveAccessionProposal) -> [String] {
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

        func requireValid(_ item: AdaptiveAccessionProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveAccessionProposal]) -> [String: [String]] {
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

    static func defaultAdaptiveAccessionProposalValidator() -> AdaptiveAccessionProposalValidator {
        return AdaptiveAccessionProposalValidator(
            rules: [
                AdaptiveAccessionProposalRequiredFacilityRule(message: "adaptive accession proposal needs a value"),
                AdaptiveAccessionProposalLimitRangeRule(min: 16, max: 80),
                AdaptiveAccessionProposalAmountRangeRule(min: 5.3, max: 1635.0),
                AdaptiveAccessionProposalCodePrefixRule(prefix: "REF"),
                AdaptiveAccessionProposalVersionRangeRule(min: 80, max: 3600),
            ]
        )
    }
}
