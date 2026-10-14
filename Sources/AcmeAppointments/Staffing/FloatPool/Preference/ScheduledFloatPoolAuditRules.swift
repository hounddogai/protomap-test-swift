import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled float pool audit must pass. Check returns its problems, or none.
    protocol ScheduledFloatPoolAuditRule {
        func check(_ item: ScheduledFloatPoolAudit) -> [String]
    }

    final class ScheduledFloatPoolAuditPayerLengthRule: ScheduledFloatPoolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFloatPoolAudit) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFloatPoolAuditCodePrefixRule: ScheduledFloatPoolAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledFloatPoolAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledFloatPoolAuditQuantityRangeRule: ScheduledFloatPoolAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFloatPoolAudit) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled float pool audit.
    final class ScheduledFloatPoolAuditValidator {
        var rules: [any ScheduledFloatPoolAuditRule]

        init(rules: [any ScheduledFloatPoolAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledFloatPoolAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledFloatPoolAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledFloatPoolAudit]) -> [String: [String]] {
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

    static func defaultScheduledFloatPoolAuditValidator() -> ScheduledFloatPoolAuditValidator {
        return ScheduledFloatPoolAuditValidator(
            rules: [
                ScheduledFloatPoolAuditPayerLengthRule(maxLength: 255),
                ScheduledFloatPoolAuditCodePrefixRule(prefix: "REF"),
                ScheduledFloatPoolAuditQuantityRangeRule(min: 64, max: 255),
            ]
        )
    }
}
