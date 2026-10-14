import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled census assignment must pass. Check returns its problems, or none.
    protocol ScheduledCensusAssignmentRule {
        func check(_ item: ScheduledCensusAssignment) -> [String]
    }

    final class ScheduledCensusAssignmentQuantityRangeRule: ScheduledCensusAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCensusAssignment) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledCensusAssignmentRequiredLabelRule: ScheduledCensusAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCensusAssignment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCensusAssignmentPayerLengthRule: ScheduledCensusAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCensusAssignment) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCensusAssignmentCodePrefixRule: ScheduledCensusAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledCensusAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledCensusAssignmentAllowedProcedureCodeRule: ScheduledCensusAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledCensusAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is above maximum"]
            }
            return []
        }
    }

    final class ScheduledCensusAssignmentRequiredPayerRule: ScheduledCensusAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCensusAssignment) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled census assignment.
    final class ScheduledCensusAssignmentValidator {
        var rules: [any ScheduledCensusAssignmentRule]

        init(rules: [any ScheduledCensusAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCensusAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCensusAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCensusAssignment]) -> [String: [String]] {
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

    static func defaultScheduledCensusAssignmentValidator() -> ScheduledCensusAssignmentValidator {
        return ScheduledCensusAssignmentValidator(
            rules: [
                ScheduledCensusAssignmentQuantityRangeRule(min: 32, max: 86400),
                ScheduledCensusAssignmentRequiredLabelRule(message: "scheduled census assignment needs a value"),
                ScheduledCensusAssignmentPayerLengthRule(maxLength: 120),
                ScheduledCensusAssignmentCodePrefixRule(prefix: "REF"),
                ScheduledCensusAssignmentAllowedProcedureCodeRule(allowed: ["batched", "lenient"]),
                ScheduledCensusAssignmentRequiredPayerRule(message: "scheduled census assignment needs an entry"),
            ]
        )
    }
}
