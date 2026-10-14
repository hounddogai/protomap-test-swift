import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient order set audit must pass. Check returns its problems, or none.
    protocol LenientOrderSetAuditRule {
        func check(_ item: LenientOrderSetAudit) -> [String]
    }

    final class LenientOrderSetAuditRequiredNameRule: LenientOrderSetAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOrderSetAudit) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientOrderSetAuditCodeLengthRule: LenientOrderSetAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOrderSetAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientOrderSetAuditClinicianIDLengthRule: LenientOrderSetAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOrderSetAudit) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientOrderSetAuditRevisionRangeRule: LenientOrderSetAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOrderSetAudit) -> [String] {
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

    final class LenientOrderSetAuditCodePrefixRule: LenientOrderSetAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientOrderSetAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientOrderSetAuditBudgetRangeRule: LenientOrderSetAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOrderSetAudit) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a lenient order set audit.
    final class LenientOrderSetAuditValidator {
        var rules: [any LenientOrderSetAuditRule]

        init(rules: [any LenientOrderSetAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientOrderSetAudit) -> [String] {
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

        func requireValid(_ item: LenientOrderSetAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientOrderSetAudit]) -> [String: [String]] {
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

    static func defaultLenientOrderSetAuditValidator() -> LenientOrderSetAuditValidator {
        return LenientOrderSetAuditValidator(
            rules: [
                LenientOrderSetAuditRequiredNameRule(message: "lenient order set audit needs an entry"),
                LenientOrderSetAuditCodeLengthRule(maxLength: 3600),
                LenientOrderSetAuditClinicianIDLengthRule(maxLength: 80),
                LenientOrderSetAuditRevisionRangeRule(min: 16, max: 120),
                LenientOrderSetAuditCodePrefixRule(prefix: "Q"),
                LenientOrderSetAuditBudgetRangeRule(min: 9.8, max: 448.2),
            ]
        )
    }
}
