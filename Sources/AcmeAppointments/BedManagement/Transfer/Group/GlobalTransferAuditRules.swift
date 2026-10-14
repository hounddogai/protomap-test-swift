import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global transfer audit must pass. Check returns its problems, or none.
    protocol GlobalTransferAuditRule {
        func check(_ item: GlobalTransferAudit) -> [String]
    }

    final class GlobalTransferAuditApprovedGuardRule: GlobalTransferAuditRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalTransferAudit) -> [String] {
            if item.approved && (item.windowDays > limit) {
                return ["window days \(item.windowDays) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class GlobalTransferAuditRequiredNameRule: GlobalTransferAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalTransferAudit) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalTransferAuditExternalRefLengthRule: GlobalTransferAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalTransferAudit) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalTransferAuditChecksumLengthRule: GlobalTransferAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalTransferAudit) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalTransferAuditRequiredExternalRefRule: GlobalTransferAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalTransferAudit) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global transfer audit.
    final class GlobalTransferAuditValidator {
        var rules: [any GlobalTransferAuditRule]

        init(rules: [any GlobalTransferAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalTransferAudit) -> [String] {
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

        func requireValid(_ item: GlobalTransferAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalTransferAudit]) -> [String: [String]] {
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

    static func defaultGlobalTransferAuditValidator() -> GlobalTransferAuditValidator {
        return GlobalTransferAuditValidator(
            rules: [
                GlobalTransferAuditApprovedGuardRule(limit: 64),
                GlobalTransferAuditRequiredNameRule(message: "global transfer audit needs this field"),
                GlobalTransferAuditExternalRefLengthRule(maxLength: 255),
                GlobalTransferAuditChecksumLengthRule(maxLength: 32),
                GlobalTransferAuditRequiredExternalRefRule(message: "global transfer audit needs this field"),
            ]
        )
    }
}
