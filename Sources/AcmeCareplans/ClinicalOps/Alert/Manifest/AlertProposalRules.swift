import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert proposal must pass. Check returns its problems, or none.
    protocol AlertProposalRule {
        func check(_ item: AlertProposal) -> [String]
    }

    final class AlertProposalFloorValueRangeRule: AlertProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertProposal) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AlertProposalCodePrefixRule: AlertProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AlertProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AlertProposalRequiredChecksumRule: AlertProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertProposal) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertProposalDiscountRangeRule: AlertProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertProposal) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert proposal.
    final class AlertProposalValidator {
        var rules: [any AlertProposalRule]

        init(rules: [any AlertProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertProposal]) -> [String: [String]] {
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

    static func defaultAlertProposalValidator() -> AlertProposalValidator {
        return AlertProposalValidator(
            rules: [
                AlertProposalFloorValueRangeRule(min: 2.3, max: 4330.8),
                AlertProposalCodePrefixRule(prefix: "OPS"),
                AlertProposalRequiredChecksumRule(message: "alert proposal needs an entry"),
                AlertProposalDiscountRangeRule(min: 0.6, max: 1438.6),
            ]
        )
    }
}
