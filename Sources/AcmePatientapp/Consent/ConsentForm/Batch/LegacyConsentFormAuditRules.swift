import AcmePlatform
import Foundation

extension Consent {
    /// A rule a legacy consent form audit must pass. Check returns its problems, or none.
    protocol LegacyConsentFormAuditRule {
        func check(_ item: LegacyConsentFormAudit) -> [String]
    }

    final class LegacyConsentFormAuditNameLengthRule: LegacyConsentFormAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyConsentFormAudit) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyConsentFormAuditRequiredNameRule: LegacyConsentFormAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyConsentFormAudit) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyConsentFormAuditQuantityRangeRule: LegacyConsentFormAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyConsentFormAudit) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyConsentFormAuditTitleLengthRule: LegacyConsentFormAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyConsentFormAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyConsentFormAuditArchivedGuardRule: LegacyConsentFormAuditRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LegacyConsentFormAudit) -> [String] {
            if item.archived && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class LegacyConsentFormAuditRequiredCodeRule: LegacyConsentFormAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyConsentFormAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy consent form audit.
    final class LegacyConsentFormAuditValidator {
        var rules: [any LegacyConsentFormAuditRule]

        init(rules: [any LegacyConsentFormAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyConsentFormAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyConsentFormAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyConsentFormAudit]) -> [String: [String]] {
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

    static func defaultLegacyConsentFormAuditValidator() -> LegacyConsentFormAuditValidator {
        return LegacyConsentFormAuditValidator(
            rules: [
                LegacyConsentFormAuditNameLengthRule(maxLength: 3600),
                LegacyConsentFormAuditRequiredNameRule(message: "legacy consent form audit needs a value"),
                LegacyConsentFormAuditQuantityRangeRule(min: 64, max: 80),
                LegacyConsentFormAuditTitleLengthRule(maxLength: 16),
                LegacyConsentFormAuditArchivedGuardRule(limit: 120),
                LegacyConsentFormAuditRequiredCodeRule(message: "legacy consent form audit needs this field"),
            ]
        )
    }
}
