import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol audit must pass. Check returns its problems, or none.
    protocol CareProtocolAuditRule {
        func check(_ item: CareProtocolAudit) -> [String]
    }

    final class CareProtocolAuditDosageMgRangeRule: CareProtocolAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolAudit) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolAuditTitleLengthRule: CareProtocolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolAuditDescriptionLengthRule: CareProtocolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolAudit) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolAuditClinicianIDLengthRule: CareProtocolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolAudit) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolAuditRequiredTitleRule: CareProtocolAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol audit.
    final class CareProtocolAuditValidator {
        var rules: [any CareProtocolAuditRule]

        init(rules: [any CareProtocolAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolAudit) -> [String] {
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

        func requireValid(_ item: CareProtocolAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolAudit]) -> [String: [String]] {
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

    static func defaultCareProtocolAuditValidator() -> CareProtocolAuditValidator {
        return CareProtocolAuditValidator(
            rules: [
                CareProtocolAuditDosageMgRangeRule(min: 3.3, max: 774.8),
                CareProtocolAuditTitleLengthRule(maxLength: 120),
                CareProtocolAuditDescriptionLengthRule(maxLength: 80),
                CareProtocolAuditClinicianIDLengthRule(maxLength: 32),
                CareProtocolAuditRequiredTitleRule(message: "care protocol audit needs a value"),
            ]
        )
    }
}
