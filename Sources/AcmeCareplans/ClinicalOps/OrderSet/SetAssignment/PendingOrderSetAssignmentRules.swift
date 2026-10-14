import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending order set assignment must pass. Check returns its problems, or none.
    protocol PendingOrderSetAssignmentRule {
        func check(_ item: PendingOrderSetAssignment) -> [String]
    }

    final class PendingOrderSetAssignmentAllowedCurrencyRule: PendingOrderSetAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingOrderSetAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is below minimum"]
            }
            return []
        }
    }

    final class PendingOrderSetAssignmentDurationMinutesRangeRule: PendingOrderSetAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOrderSetAssignment) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingOrderSetAssignmentCodePrefixRule: PendingOrderSetAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingOrderSetAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending order set assignment.
    final class PendingOrderSetAssignmentValidator {
        var rules: [any PendingOrderSetAssignmentRule]

        init(rules: [any PendingOrderSetAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingOrderSetAssignment) -> [String] {
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

        func requireValid(_ item: PendingOrderSetAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingOrderSetAssignment]) -> [String: [String]] {
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

    static func defaultPendingOrderSetAssignmentValidator() -> PendingOrderSetAssignmentValidator {
        return PendingOrderSetAssignmentValidator(
            rules: [
                PendingOrderSetAssignmentAllowedCurrencyRule(allowed: ["legacy"]),
                PendingOrderSetAssignmentDurationMinutesRangeRule(min: 1000, max: 1000),
                PendingOrderSetAssignmentCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
