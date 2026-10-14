import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending float pool audit must pass. Check returns its problems, or none.
    protocol PendingFloatPoolAuditRule {
        func check(_ item: PendingFloatPoolAudit) -> [String]
    }

    final class PendingFloatPoolAuditSpecialtyLengthRule: PendingFloatPoolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingFloatPoolAudit) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingFloatPoolAuditLabelLengthRule: PendingFloatPoolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingFloatPoolAudit) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingFloatPoolAuditPhoneLengthRule: PendingFloatPoolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingFloatPoolAudit) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending float pool audit.
    final class PendingFloatPoolAuditValidator {
        var rules: [any PendingFloatPoolAuditRule]

        init(rules: [any PendingFloatPoolAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingFloatPoolAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingFloatPoolAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingFloatPoolAudit]) -> [String: [String]] {
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

    static func defaultPendingFloatPoolAuditValidator() -> PendingFloatPoolAuditValidator {
        return PendingFloatPoolAuditValidator(
            rules: [
                PendingFloatPoolAuditSpecialtyLengthRule(maxLength: 3600),
                PendingFloatPoolAuditLabelLengthRule(maxLength: 3600),
                PendingFloatPoolAuditPhoneLengthRule(maxLength: 16),
            ]
        )
    }
}
