import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual risk score audit must pass. Check returns its problems, or none.
    protocol ManualRiskScoreAuditRule {
        func check(_ item: ManualRiskScoreAudit) -> [String]
    }

    final class ManualRiskScoreAuditRequiredEncounterIDRule: ManualRiskScoreAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRiskScoreAudit) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRiskScoreAuditRequiredCodeRule: ManualRiskScoreAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRiskScoreAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRiskScoreAuditLimitRangeRule: ManualRiskScoreAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRiskScoreAudit) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualRiskScoreAuditActiveGuardRule: ManualRiskScoreAuditRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ManualRiskScoreAudit) -> [String] {
            if item.active && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ManualRiskScoreAuditTimezoneLengthRule: ManualRiskScoreAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRiskScoreAudit) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRiskScoreAuditCodePrefixRule: ManualRiskScoreAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualRiskScoreAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual risk score audit.
    final class ManualRiskScoreAuditValidator {
        var rules: [any ManualRiskScoreAuditRule]

        init(rules: [any ManualRiskScoreAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRiskScoreAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualRiskScoreAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRiskScoreAudit]) -> [String: [String]] {
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

    static func defaultManualRiskScoreAuditValidator() -> ManualRiskScoreAuditValidator {
        return ManualRiskScoreAuditValidator(
            rules: [
                ManualRiskScoreAuditRequiredEncounterIDRule(message: "manual risk score audit needs this field"),
                ManualRiskScoreAuditRequiredCodeRule(message: "manual risk score audit needs a value"),
                ManualRiskScoreAuditLimitRangeRule(min: 16, max: 86400),
                ManualRiskScoreAuditActiveGuardRule(limit: 16),
                ManualRiskScoreAuditTimezoneLengthRule(maxLength: 32),
                ManualRiskScoreAuditCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
