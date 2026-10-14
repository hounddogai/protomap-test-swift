import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional reference range audit must pass. Check returns its problems, or none.
    protocol RegionalReferenceRangeAuditRule {
        func check(_ item: RegionalReferenceRangeAudit) -> [String]
    }

    final class RegionalReferenceRangeAuditActiveGuardRule: RegionalReferenceRangeAuditRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RegionalReferenceRangeAudit) -> [String] {
            if item.active && (item.rate > limit) {
                return ["rate \(item.rate) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class RegionalReferenceRangeAuditAllowedClinicianIDRule: RegionalReferenceRangeAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalReferenceRangeAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is inconsistent"]
            }
            return []
        }
    }

    final class RegionalReferenceRangeAuditCodeLengthRule: RegionalReferenceRangeAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalReferenceRangeAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional reference range audit.
    final class RegionalReferenceRangeAuditValidator {
        var rules: [any RegionalReferenceRangeAuditRule]

        init(rules: [any RegionalReferenceRangeAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalReferenceRangeAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalReferenceRangeAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalReferenceRangeAudit]) -> [String: [String]] {
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

    static func defaultRegionalReferenceRangeAuditValidator() -> RegionalReferenceRangeAuditValidator {
        return RegionalReferenceRangeAuditValidator(
            rules: [
                RegionalReferenceRangeAuditActiveGuardRule(limit: 1.8),
                RegionalReferenceRangeAuditAllowedClinicianIDRule(allowed: ["fallback", "pending"]),
                RegionalReferenceRangeAuditCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
