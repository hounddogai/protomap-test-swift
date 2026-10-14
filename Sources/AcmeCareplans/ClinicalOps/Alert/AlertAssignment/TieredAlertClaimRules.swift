import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered alert claim must pass. Check returns its problems, or none.
    protocol TieredAlertClaimRule {
        func check(_ item: TieredAlertClaim) -> [String]
    }

    final class TieredAlertClaimTitleLengthRule: TieredAlertClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredAlertClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredAlertClaimCodePrefixRule: TieredAlertClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredAlertClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredAlertClaimRequiredClinicianIDRule: TieredAlertClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAlertClaim) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAlertClaimClinicianIDLengthRule: TieredAlertClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredAlertClaim) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredAlertClaimRequiredCodeRule: TieredAlertClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAlertClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered alert claim.
    final class TieredAlertClaimValidator {
        var rules: [any TieredAlertClaimRule]

        init(rules: [any TieredAlertClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredAlertClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredAlertClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredAlertClaim]) -> [String: [String]] {
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

    static func defaultTieredAlertClaimValidator() -> TieredAlertClaimValidator {
        return TieredAlertClaimValidator(
            rules: [
                TieredAlertClaimTitleLengthRule(maxLength: 16),
                TieredAlertClaimCodePrefixRule(prefix: "X"),
                TieredAlertClaimRequiredClinicianIDRule(message: "tiered alert claim needs this field"),
                TieredAlertClaimClinicianIDLengthRule(maxLength: 255),
                TieredAlertClaimRequiredCodeRule(message: "tiered alert claim needs an entry"),
            ]
        )
    }
}
