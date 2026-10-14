import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census milestone must pass. Check returns its problems, or none.
    protocol CensusMilestoneRule {
        func check(_ item: CensusMilestone) -> [String]
    }

    final class CensusMilestoneCodePrefixRule: CensusMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusMilestoneAmountRangeRule: CensusMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusMilestone) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CensusMilestoneRequiredTitleRule: CensusMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a census milestone.
    final class CensusMilestoneValidator {
        var rules: [any CensusMilestoneRule]

        init(rules: [any CensusMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusMilestone]) -> [String: [String]] {
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

    static func defaultCensusMilestoneValidator() -> CensusMilestoneValidator {
        return CensusMilestoneValidator(
            rules: [
                CensusMilestoneCodePrefixRule(prefix: "Q"),
                CensusMilestoneAmountRangeRule(min: 2.7, max: 1933.9),
                CensusMilestoneRequiredTitleRule(message: "census milestone needs an entry"),
            ]
        )
    }
}
