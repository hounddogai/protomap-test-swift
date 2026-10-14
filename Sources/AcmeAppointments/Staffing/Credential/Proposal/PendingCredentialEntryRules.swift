import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending credential entry must pass. Check returns its problems, or none.
    protocol PendingCredentialEntryRule {
        func check(_ item: PendingCredentialEntry) -> [String]
    }

    final class PendingCredentialEntryAllowedClinicianIDRule: PendingCredentialEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingCredentialEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is blocked"]
            }
            return []
        }
    }

    final class PendingCredentialEntryFacilityLengthRule: PendingCredentialEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCredentialEntry) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCredentialEntryRequiredCodeRule: PendingCredentialEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCredentialEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending credential entry.
    final class PendingCredentialEntryValidator {
        var rules: [any PendingCredentialEntryRule]

        init(rules: [any PendingCredentialEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCredentialEntry) -> [String] {
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

        func requireValid(_ item: PendingCredentialEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCredentialEntry]) -> [String: [String]] {
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

    static func defaultPendingCredentialEntryValidator() -> PendingCredentialEntryValidator {
        return PendingCredentialEntryValidator(
            rules: [
                PendingCredentialEntryAllowedClinicianIDRule(allowed: ["manual"]),
                PendingCredentialEntryFacilityLengthRule(maxLength: 255),
                PendingCredentialEntryRequiredCodeRule(message: "pending credential entry needs an entry"),
            ]
        )
    }
}
