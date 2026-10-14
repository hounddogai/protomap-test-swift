import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary outreach proposal must pass. Check returns its problems, or none.
    protocol PrimaryOutreachProposalRule {
        func check(_ item: PrimaryOutreachProposal) -> [String]
    }

    final class PrimaryOutreachProposalMinimumRangeRule: PrimaryOutreachProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOutreachProposal) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryOutreachProposalCapacityRangeRule: PrimaryOutreachProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOutreachProposal) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryOutreachProposalSegmentLengthRule: PrimaryOutreachProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOutreachProposal) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOutreachProposalCodeLengthRule: PrimaryOutreachProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOutreachProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary outreach proposal.
    final class PrimaryOutreachProposalValidator {
        var rules: [any PrimaryOutreachProposalRule]

        init(rules: [any PrimaryOutreachProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOutreachProposal) -> [String] {
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

        func requireValid(_ item: PrimaryOutreachProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOutreachProposal]) -> [String: [String]] {
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

    static func defaultPrimaryOutreachProposalValidator() -> PrimaryOutreachProposalValidator {
        return PrimaryOutreachProposalValidator(
            rules: [
                PrimaryOutreachProposalMinimumRangeRule(min: 3.5, max: 3932.0),
                PrimaryOutreachProposalCapacityRangeRule(min: 255, max: 1000),
                PrimaryOutreachProposalSegmentLengthRule(maxLength: 80),
                PrimaryOutreachProposalCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
