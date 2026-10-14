import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning proposal must pass. Check returns its problems, or none.
    protocol CleaningProposalRule {
        func check(_ item: CleaningProposal) -> [String]
    }

    final class CleaningProposalWindowDaysRangeRule: CleaningProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningProposal) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CleaningProposalThresholdRangeRule: CleaningProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningProposal) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CleaningProposalMarginRangeRule: CleaningProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningProposal) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning proposal.
    final class CleaningProposalValidator {
        var rules: [any CleaningProposalRule]

        init(rules: [any CleaningProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningProposal]) -> [String: [String]] {
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

    static func defaultCleaningProposalValidator() -> CleaningProposalValidator {
        return CleaningProposalValidator(
            rules: [
                CleaningProposalWindowDaysRangeRule(min: 255, max: 255),
                CleaningProposalThresholdRangeRule(min: 5.1, max: 2124.8),
                CleaningProposalMarginRangeRule(min: 0.9, max: 1756.3),
            ]
        )
    }
}
