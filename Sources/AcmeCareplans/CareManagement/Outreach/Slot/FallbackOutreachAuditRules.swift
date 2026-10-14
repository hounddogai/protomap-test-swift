import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback outreach audit must pass. Check returns its problems, or none.
    protocol FallbackOutreachAuditRule {
        func check(_ item: FallbackOutreachAudit) -> [String]
    }

    final class FallbackOutreachAuditFacilityLengthRule: FallbackOutreachAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackOutreachAudit) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackOutreachAuditRequiredTitleRule: FallbackOutreachAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOutreachAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackOutreachAuditCodeLengthRule: FallbackOutreachAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackOutreachAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackOutreachAuditCodePrefixRule: FallbackOutreachAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackOutreachAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback outreach audit.
    final class FallbackOutreachAuditValidator {
        var rules: [any FallbackOutreachAuditRule]

        init(rules: [any FallbackOutreachAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackOutreachAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackOutreachAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackOutreachAudit]) -> [String: [String]] {
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

    static func defaultFallbackOutreachAuditValidator() -> FallbackOutreachAuditValidator {
        return FallbackOutreachAuditValidator(
            rules: [
                FallbackOutreachAuditFacilityLengthRule(maxLength: 120),
                FallbackOutreachAuditRequiredTitleRule(message: "fallback outreach audit needs a value"),
                FallbackOutreachAuditCodeLengthRule(maxLength: 255),
                FallbackOutreachAuditCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
