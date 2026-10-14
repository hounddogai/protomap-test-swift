import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered care gap audit must pass. Check returns its problems, or none.
    protocol TieredCareGapAuditRule {
        func check(_ item: TieredCareGapAudit) -> [String]
    }

    final class TieredCareGapAuditAllergyLengthRule: TieredCareGapAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareGapAudit) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCareGapAuditCodeLengthRule: TieredCareGapAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCareGapAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCareGapAuditRequiredAllergyRule: TieredCareGapAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareGapAudit) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareGapAuditRequiredCodeRule: TieredCareGapAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCareGapAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCareGapAuditAllowedChecksumRule: TieredCareGapAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredCareGapAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is not allowed"]
            }
            return []
        }
    }

    final class TieredCareGapAuditCodePrefixRule: TieredCareGapAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredCareGapAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered care gap audit.
    final class TieredCareGapAuditValidator {
        var rules: [any TieredCareGapAuditRule]

        init(rules: [any TieredCareGapAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCareGapAudit) -> [String] {
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

        func requireValid(_ item: TieredCareGapAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCareGapAudit]) -> [String: [String]] {
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

    static func defaultTieredCareGapAuditValidator() -> TieredCareGapAuditValidator {
        return TieredCareGapAuditValidator(
            rules: [
                TieredCareGapAuditAllergyLengthRule(maxLength: 64),
                TieredCareGapAuditCodeLengthRule(maxLength: 32),
                TieredCareGapAuditRequiredAllergyRule(message: "tiered care gap audit needs an entry"),
                TieredCareGapAuditRequiredCodeRule(message: "tiered care gap audit needs a value"),
                TieredCareGapAuditAllowedChecksumRule(allowed: ["seasonal", "tiered", "weighted"]),
                TieredCareGapAuditCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
