import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling specimen proposal must pass. Check returns its problems, or none.
    protocol RollingSpecimenProposalRule {
        func check(_ item: RollingSpecimenProposal) -> [String]
    }

    final class RollingSpecimenProposalExternalRefLengthRule: RollingSpecimenProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSpecimenProposal) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingSpecimenProposalAttemptsRangeRule: RollingSpecimenProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingSpecimenProposal) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingSpecimenProposalNameLengthRule: RollingSpecimenProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSpecimenProposal) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingSpecimenProposalAllowedExternalRefRule: RollingSpecimenProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingSpecimenProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is inconsistent"]
            }
            return []
        }
    }

    final class RollingSpecimenProposalChannelLengthRule: RollingSpecimenProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSpecimenProposal) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling specimen proposal.
    final class RollingSpecimenProposalValidator {
        var rules: [any RollingSpecimenProposalRule]

        init(rules: [any RollingSpecimenProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingSpecimenProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingSpecimenProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingSpecimenProposal]) -> [String: [String]] {
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

    static func defaultRollingSpecimenProposalValidator() -> RollingSpecimenProposalValidator {
        return RollingSpecimenProposalValidator(
            rules: [
                RollingSpecimenProposalExternalRefLengthRule(maxLength: 3600),
                RollingSpecimenProposalAttemptsRangeRule(min: 16, max: 16),
                RollingSpecimenProposalNameLengthRule(maxLength: 3600),
                RollingSpecimenProposalAllowedExternalRefRule(allowed: ["primary", "legacy", "regional"]),
                RollingSpecimenProposalChannelLengthRule(maxLength: 64),
            ]
        )
    }
}
