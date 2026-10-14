import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted referral audit must pass. Check returns its problems, or none.
    protocol WeightedReferralAuditRule {
        func check(_ item: WeightedReferralAudit) -> [String]
    }

    final class WeightedReferralAuditRequiredNameRule: WeightedReferralAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralAudit) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferralAuditRequiredCodeRule: WeightedReferralAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferralAuditRequiredClinicianIDRule: WeightedReferralAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralAudit) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferralAuditCodeLengthRule: WeightedReferralAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReferralAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedReferralAuditAllowedPayerRule: WeightedReferralAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedReferralAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted referral audit.
    final class WeightedReferralAuditValidator {
        var rules: [any WeightedReferralAuditRule]

        init(rules: [any WeightedReferralAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedReferralAudit) -> [String] {
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

        func requireValid(_ item: WeightedReferralAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedReferralAudit]) -> [String: [String]] {
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

    static func defaultWeightedReferralAuditValidator() -> WeightedReferralAuditValidator {
        return WeightedReferralAuditValidator(
            rules: [
                WeightedReferralAuditRequiredNameRule(message: "weighted referral audit needs this field"),
                WeightedReferralAuditRequiredCodeRule(message: "weighted referral audit needs a value"),
                WeightedReferralAuditRequiredClinicianIDRule(message: "weighted referral audit needs a value"),
                WeightedReferralAuditCodeLengthRule(maxLength: 32),
                WeightedReferralAuditAllowedPayerRule(allowed: []),
            ]
        )
    }
}
