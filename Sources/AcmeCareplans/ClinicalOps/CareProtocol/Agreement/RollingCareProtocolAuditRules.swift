import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling care protocol audit must pass. Check returns its problems, or none.
    protocol RollingCareProtocolAuditRule {
        func check(_ item: RollingCareProtocolAudit) -> [String]
    }

    final class RollingCareProtocolAuditCodeLengthRule: RollingCareProtocolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareProtocolAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareProtocolAuditFacilityLengthRule: RollingCareProtocolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCareProtocolAudit) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCareProtocolAuditRequiredLabelRule: RollingCareProtocolAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCareProtocolAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling care protocol audit.
    final class RollingCareProtocolAuditValidator {
        var rules: [any RollingCareProtocolAuditRule]

        init(rules: [any RollingCareProtocolAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCareProtocolAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingCareProtocolAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCareProtocolAudit]) -> [String: [String]] {
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

    static func defaultRollingCareProtocolAuditValidator() -> RollingCareProtocolAuditValidator {
        return RollingCareProtocolAuditValidator(
            rules: [
                RollingCareProtocolAuditCodeLengthRule(maxLength: 16),
                RollingCareProtocolAuditFacilityLengthRule(maxLength: 32),
                RollingCareProtocolAuditRequiredLabelRule(message: "rolling care protocol audit needs an entry"),
            ]
        )
    }
}
