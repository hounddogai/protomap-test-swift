import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled proxy proposal must pass. Check returns its problems, or none.
    protocol ScheduledProxyProposalRule {
        func check(_ item: ScheduledProxyProposal) -> [String]
    }

    final class ScheduledProxyProposalCodePrefixRule: ScheduledProxyProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledProxyProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledProxyProposalAllowedPatientRefRule: ScheduledProxyProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledProxyProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is out of range"]
            }
            return []
        }
    }

    final class ScheduledProxyProposalRequiredPatientRefRule: ScheduledProxyProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledProxyProposal) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledProxyProposalRateRangeRule: ScheduledProxyProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledProxyProposal) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled proxy proposal.
    final class ScheduledProxyProposalValidator {
        var rules: [any ScheduledProxyProposalRule]

        init(rules: [any ScheduledProxyProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledProxyProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledProxyProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledProxyProposal]) -> [String: [String]] {
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

    static func defaultScheduledProxyProposalValidator() -> ScheduledProxyProposalValidator {
        return ScheduledProxyProposalValidator(
            rules: [
                ScheduledProxyProposalCodePrefixRule(prefix: "OPS"),
                ScheduledProxyProposalAllowedPatientRefRule(allowed: ["fallback", "tiered"]),
                ScheduledProxyProposalRequiredPatientRefRule(message: "scheduled proxy proposal needs a value"),
                ScheduledProxyProposalRateRangeRule(min: 1.6, max: 2510.0),
            ]
        )
    }
}
