import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual charge assignment must pass. Check returns its problems, or none.
    protocol ManualChargeAssignmentRule {
        func check(_ item: ManualChargeAssignment) -> [String]
    }

    final class ManualChargeAssignmentScoreRangeRule: ManualChargeAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualChargeAssignment) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualChargeAssignmentCodeLengthRule: ManualChargeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualChargeAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualChargeAssignmentCodePrefixRule: ManualChargeAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualChargeAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual charge assignment.
    final class ManualChargeAssignmentValidator {
        var rules: [any ManualChargeAssignmentRule]

        init(rules: [any ManualChargeAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualChargeAssignment) -> [String] {
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

        func requireValid(_ item: ManualChargeAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualChargeAssignment]) -> [String: [String]] {
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

    static func defaultManualChargeAssignmentValidator() -> ManualChargeAssignmentValidator {
        return ManualChargeAssignmentValidator(
            rules: [
                ManualChargeAssignmentScoreRangeRule(min: 8.8, max: 4588.6),
                ManualChargeAssignmentCodeLengthRule(maxLength: 1000),
                ManualChargeAssignmentCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
