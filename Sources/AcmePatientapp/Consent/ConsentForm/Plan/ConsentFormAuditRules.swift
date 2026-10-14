import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form audit must pass. Check returns its problems, or none.
    protocol ConsentFormAuditRule {
        func check(_ item: ConsentFormAudit) -> [String]
    }

    final class ConsentFormAuditCodePrefixRule: ConsentFormAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ConsentFormAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ConsentFormAuditCapacityRangeRule: ConsentFormAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormAudit) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ConsentFormAuditRequiredNameRule: ConsentFormAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormAudit) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a consent form audit.
    final class ConsentFormAuditValidator {
        var rules: [any ConsentFormAuditRule]

        init(rules: [any ConsentFormAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormAudit) -> [String] {
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

        func requireValid(_ item: ConsentFormAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormAudit]) -> [String: [String]] {
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

    static func defaultConsentFormAuditValidator() -> ConsentFormAuditValidator {
        return ConsentFormAuditValidator(
            rules: [
                ConsentFormAuditCodePrefixRule(prefix: "ACM"),
                ConsentFormAuditCapacityRangeRule(min: 255, max: 1000),
                ConsentFormAuditRequiredNameRule(message: "consent form audit needs this field"),
            ]
        )
    }
}
