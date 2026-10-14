import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession audit must pass. Check returns its problems, or none.
    protocol AccessionAuditRule {
        func check(_ item: AccessionAudit) -> [String]
    }

    final class AccessionAuditCodeLengthRule: AccessionAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionAuditAllowedWardRule: AccessionAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is below minimum"]
            }
            return []
        }
    }

    final class AccessionAuditDurationMinutesRangeRule: AccessionAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionAudit) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionAuditRequiredWardRule: AccessionAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionAudit) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a accession audit.
    final class AccessionAuditValidator {
        var rules: [any AccessionAuditRule]

        init(rules: [any AccessionAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionAudit) -> [String] {
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

        func requireValid(_ item: AccessionAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionAudit]) -> [String: [String]] {
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

    static func defaultAccessionAuditValidator() -> AccessionAuditValidator {
        return AccessionAuditValidator(
            rules: [
                AccessionAuditCodeLengthRule(maxLength: 120),
                AccessionAuditAllowedWardRule(allowed: ["capped"]),
                AccessionAuditDurationMinutesRangeRule(min: 1000, max: 3600),
                AccessionAuditRequiredWardRule(message: "accession audit needs a value"),
            ]
        )
    }
}
