import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization proposal must pass. Check returns its problems, or none.
    protocol AuthorizationProposalRule {
        func check(_ item: AuthorizationProposal) -> [String]
    }

    final class AuthorizationProposalAllowedPatientRefRule: AuthorizationProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AuthorizationProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is out of range"]
            }
            return []
        }
    }

    final class AuthorizationProposalRateRangeRule: AuthorizationProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationProposal) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AuthorizationProposalEndsAtRangeRule: AuthorizationProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationProposal) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AuthorizationProposalLabelLengthRule: AuthorizationProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationProposal) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization proposal.
    final class AuthorizationProposalValidator {
        var rules: [any AuthorizationProposalRule]

        init(rules: [any AuthorizationProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationProposal) -> [String] {
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

        func requireValid(_ item: AuthorizationProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationProposal]) -> [String: [String]] {
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

    static func defaultAuthorizationProposalValidator() -> AuthorizationProposalValidator {
        return AuthorizationProposalValidator(
            rules: [
                AuthorizationProposalAllowedPatientRefRule(allowed: ["seasonal"]),
                AuthorizationProposalRateRangeRule(min: 8.2, max: 2281.3),
                AuthorizationProposalEndsAtRangeRule(min: 80, max: 1000),
                AuthorizationProposalLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
