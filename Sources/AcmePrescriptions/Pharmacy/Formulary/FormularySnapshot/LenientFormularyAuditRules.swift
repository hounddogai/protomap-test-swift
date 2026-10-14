import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient formulary audit must pass. Check returns its problems, or none.
    protocol LenientFormularyAuditRule {
        func check(_ item: LenientFormularyAudit) -> [String]
    }

    final class LenientFormularyAuditAllowedSpecialtyRule: LenientFormularyAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientFormularyAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is stale"]
            }
            return []
        }
    }

    final class LenientFormularyAuditCodeLengthRule: LenientFormularyAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientFormularyAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientFormularyAuditCodePrefixRule: LenientFormularyAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientFormularyAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient formulary audit.
    final class LenientFormularyAuditValidator {
        var rules: [any LenientFormularyAuditRule]

        init(rules: [any LenientFormularyAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientFormularyAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientFormularyAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientFormularyAudit]) -> [String: [String]] {
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

    static func defaultLenientFormularyAuditValidator() -> LenientFormularyAuditValidator {
        return LenientFormularyAuditValidator(
            rules: [
                LenientFormularyAuditAllowedSpecialtyRule(allowed: ["capped", "lenient", "adaptive"]),
                LenientFormularyAuditCodeLengthRule(maxLength: 32),
                LenientFormularyAuditCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
