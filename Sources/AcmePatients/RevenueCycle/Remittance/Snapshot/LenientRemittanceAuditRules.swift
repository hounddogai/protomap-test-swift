import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient remittance audit must pass. Check returns its problems, or none.
    protocol LenientRemittanceAuditRule {
        func check(_ item: LenientRemittanceAudit) -> [String]
    }

    final class LenientRemittanceAuditRequiredCodeRule: LenientRemittanceAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRemittanceAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientRemittanceAuditAllowedClinicianIDRule: LenientRemittanceAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientRemittanceAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is too long"]
            }
            return []
        }
    }

    final class LenientRemittanceAuditCopayRangeRule: LenientRemittanceAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRemittanceAudit) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientRemittanceAuditTitleLengthRule: LenientRemittanceAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRemittanceAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient remittance audit.
    final class LenientRemittanceAuditValidator {
        var rules: [any LenientRemittanceAuditRule]

        init(rules: [any LenientRemittanceAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRemittanceAudit) -> [String] {
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

        func requireValid(_ item: LenientRemittanceAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRemittanceAudit]) -> [String: [String]] {
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

    static func defaultLenientRemittanceAuditValidator() -> LenientRemittanceAuditValidator {
        return LenientRemittanceAuditValidator(
            rules: [
                LenientRemittanceAuditRequiredCodeRule(message: "lenient remittance audit needs this field"),
                LenientRemittanceAuditAllowedClinicianIDRule(allowed: ["capped", "tiered", "primary"]),
                LenientRemittanceAuditCopayRangeRule(min: 7.5, max: 3288.9),
                LenientRemittanceAuditTitleLengthRule(maxLength: 3600),
            ]
        )
    }
}
