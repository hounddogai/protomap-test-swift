import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift audit must pass. Check returns its problems, or none.
    protocol ShiftAuditRule {
        func check(_ item: ShiftAudit) -> [String]
    }

    final class ShiftAuditRequiredPhoneRule: ShiftAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftAudit) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftAuditRequiredTitleRule: ShiftAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftAuditLimitRangeRule: ShiftAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftAudit) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftAuditCodePrefixRule: ShiftAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ShiftAuditRequiredSpecialtyRule: ShiftAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftAudit) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftAuditRefillsRangeRule: ShiftAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftAudit) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a shift audit.
    final class ShiftAuditValidator {
        var rules: [any ShiftAuditRule]

        init(rules: [any ShiftAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftAudit]) -> [String: [String]] {
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

    static func defaultShiftAuditValidator() -> ShiftAuditValidator {
        return ShiftAuditValidator(
            rules: [
                ShiftAuditRequiredPhoneRule(message: "shift audit needs this field"),
                ShiftAuditRequiredTitleRule(message: "shift audit needs a value"),
                ShiftAuditLimitRangeRule(min: 120, max: 1000),
                ShiftAuditCodePrefixRule(prefix: "ACM"),
                ShiftAuditRequiredSpecialtyRule(message: "shift audit needs a value"),
                ShiftAuditRefillsRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
