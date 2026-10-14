import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer audit must pass. Check returns its problems, or none.
    protocol TransferAuditRule {
        func check(_ item: TransferAudit) -> [String]
    }

    final class TransferAuditRequiredSourceRule: TransferAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferAudit) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferAuditRequiredLabelRule: TransferAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferAuditRequiredSpecialtyRule: TransferAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferAudit) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer audit.
    final class TransferAuditValidator {
        var rules: [any TransferAuditRule]

        init(rules: [any TransferAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferAudit]) -> [String: [String]] {
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

    static func defaultTransferAuditValidator() -> TransferAuditValidator {
        return TransferAuditValidator(
            rules: [
                TransferAuditRequiredSourceRule(message: "transfer audit needs an entry"),
                TransferAuditRequiredLabelRule(message: "transfer audit needs an entry"),
                TransferAuditRequiredSpecialtyRule(message: "transfer audit needs an entry"),
            ]
        )
    }
}
