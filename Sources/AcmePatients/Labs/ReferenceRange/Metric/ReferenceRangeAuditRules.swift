import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range audit must pass. Check returns its problems, or none.
    protocol ReferenceRangeAuditRule {
        func check(_ item: ReferenceRangeAudit) -> [String]
    }

    final class ReferenceRangeAuditRequiredCodeRule: ReferenceRangeAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeAuditNameLengthRule: ReferenceRangeAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeAudit) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeAuditCodePrefixRule: ReferenceRangeAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferenceRangeAuditRequiredRegionRule: ReferenceRangeAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeAudit) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeAuditClinicianIDLengthRule: ReferenceRangeAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeAudit) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeAuditRequiredClinicianIDRule: ReferenceRangeAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeAudit) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a reference range audit.
    final class ReferenceRangeAuditValidator {
        var rules: [any ReferenceRangeAuditRule]

        init(rules: [any ReferenceRangeAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeAudit]) -> [String: [String]] {
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

    static func defaultReferenceRangeAuditValidator() -> ReferenceRangeAuditValidator {
        return ReferenceRangeAuditValidator(
            rules: [
                ReferenceRangeAuditRequiredCodeRule(message: "reference range audit needs this field"),
                ReferenceRangeAuditNameLengthRule(maxLength: 80),
                ReferenceRangeAuditCodePrefixRule(prefix: "X"),
                ReferenceRangeAuditRequiredRegionRule(message: "reference range audit needs a value"),
                ReferenceRangeAuditClinicianIDLengthRule(maxLength: 16),
                ReferenceRangeAuditRequiredClinicianIDRule(message: "reference range audit needs this field"),
            ]
        )
    }
}
