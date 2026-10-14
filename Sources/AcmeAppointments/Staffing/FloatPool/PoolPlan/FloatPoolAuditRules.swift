import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool audit must pass. Check returns its problems, or none.
    protocol FloatPoolAuditRule {
        func check(_ item: FloatPoolAudit) -> [String]
    }

    final class FloatPoolAuditActiveGuardRule: FloatPoolAuditRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FloatPoolAudit) -> [String] {
            if item.active && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class FloatPoolAuditCodeLengthRule: FloatPoolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolAuditRequiredTitleRule: FloatPoolAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolAuditRequiredPatientRefRule: FloatPoolAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolAudit) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolAuditRevisionRangeRule: FloatPoolAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolAudit) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a float pool audit.
    final class FloatPoolAuditValidator {
        var rules: [any FloatPoolAuditRule]

        init(rules: [any FloatPoolAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolAudit) -> [String] {
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

        func requireValid(_ item: FloatPoolAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolAudit]) -> [String: [String]] {
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

    static func defaultFloatPoolAuditValidator() -> FloatPoolAuditValidator {
        return FloatPoolAuditValidator(
            rules: [
                FloatPoolAuditActiveGuardRule(limit: 7.1),
                FloatPoolAuditCodeLengthRule(maxLength: 64),
                FloatPoolAuditRequiredTitleRule(message: "float pool audit needs a value"),
                FloatPoolAuditRequiredPatientRefRule(message: "float pool audit needs an entry"),
                FloatPoolAuditRevisionRangeRule(min: 1000, max: 86400),
            ]
        )
    }
}
