import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped remittance audit must pass. Check returns its problems, or none.
    protocol CappedRemittanceAuditRule {
        func check(_ item: CappedRemittanceAudit) -> [String]
    }

    final class CappedRemittanceAuditTitleLengthRule: CappedRemittanceAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRemittanceAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRemittanceAuditBatchSizeRangeRule: CappedRemittanceAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedRemittanceAudit) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedRemittanceAuditRequiredTitleRule: CappedRemittanceAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRemittanceAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRemittanceAuditRequiredProcedureCodeRule: CappedRemittanceAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRemittanceAudit) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRemittanceAuditVisibleGuardRule: CappedRemittanceAuditRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CappedRemittanceAudit) -> [String] {
            if item.visible && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class CappedRemittanceAuditCodeLengthRule: CappedRemittanceAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRemittanceAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped remittance audit.
    final class CappedRemittanceAuditValidator {
        var rules: [any CappedRemittanceAuditRule]

        init(rules: [any CappedRemittanceAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRemittanceAudit) -> [String] {
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

        func requireValid(_ item: CappedRemittanceAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRemittanceAudit]) -> [String: [String]] {
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

    static func defaultCappedRemittanceAuditValidator() -> CappedRemittanceAuditValidator {
        return CappedRemittanceAuditValidator(
            rules: [
                CappedRemittanceAuditTitleLengthRule(maxLength: 16),
                CappedRemittanceAuditBatchSizeRangeRule(min: 16, max: 120),
                CappedRemittanceAuditRequiredTitleRule(message: "capped remittance audit needs this field"),
                CappedRemittanceAuditRequiredProcedureCodeRule(message: "capped remittance audit needs a value"),
                CappedRemittanceAuditVisibleGuardRule(limit: 2.7),
                CappedRemittanceAuditCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
