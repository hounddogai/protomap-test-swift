import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global risk score audit must pass. Check returns its problems, or none.
    protocol GlobalRiskScoreAuditRule {
        func check(_ item: GlobalRiskScoreAudit) -> [String]
    }

    final class GlobalRiskScoreAuditArchivedGuardRule: GlobalRiskScoreAuditRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalRiskScoreAudit) -> [String] {
            if item.archived && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class GlobalRiskScoreAuditRequiredCodeRule: GlobalRiskScoreAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalRiskScoreAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalRiskScoreAuditUnitLengthRule: GlobalRiskScoreAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRiskScoreAudit) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalRiskScoreAuditRefillsRangeRule: GlobalRiskScoreAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalRiskScoreAudit) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalRiskScoreAuditVersionRangeRule: GlobalRiskScoreAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalRiskScoreAudit) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalRiskScoreAuditCodeLengthRule: GlobalRiskScoreAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRiskScoreAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global risk score audit.
    final class GlobalRiskScoreAuditValidator {
        var rules: [any GlobalRiskScoreAuditRule]

        init(rules: [any GlobalRiskScoreAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalRiskScoreAudit) -> [String] {
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

        func requireValid(_ item: GlobalRiskScoreAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalRiskScoreAudit]) -> [String: [String]] {
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

    static func defaultGlobalRiskScoreAuditValidator() -> GlobalRiskScoreAuditValidator {
        return GlobalRiskScoreAuditValidator(
            rules: [
                GlobalRiskScoreAuditArchivedGuardRule(limit: 86400),
                GlobalRiskScoreAuditRequiredCodeRule(message: "global risk score audit needs this field"),
                GlobalRiskScoreAuditUnitLengthRule(maxLength: 86400),
                GlobalRiskScoreAuditRefillsRangeRule(min: 80, max: 86400),
                GlobalRiskScoreAuditVersionRangeRule(min: 16, max: 120),
                GlobalRiskScoreAuditCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
