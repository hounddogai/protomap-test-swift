import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential entry must pass. Check returns its problems, or none.
    protocol CredentialEntryRule {
        func check(_ item: CredentialEntry) -> [String]
    }

    final class CredentialEntryAllowedSourceRule: CredentialEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CredentialEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is missing"]
            }
            return []
        }
    }

    final class CredentialEntryBedLengthRule: CredentialEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialEntry) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialEntryDosageMgRangeRule: CredentialEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialEntry) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CredentialEntryFacilityLengthRule: CredentialEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialEntry) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential entry.
    final class CredentialEntryValidator {
        var rules: [any CredentialEntryRule]

        init(rules: [any CredentialEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialEntry) -> [String] {
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

        func requireValid(_ item: CredentialEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialEntry]) -> [String: [String]] {
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

    static func defaultCredentialEntryValidator() -> CredentialEntryValidator {
        return CredentialEntryValidator(
            rules: [
                CredentialEntryAllowedSourceRule(allowed: ["rolling"]),
                CredentialEntryBedLengthRule(maxLength: 86400),
                CredentialEntryDosageMgRangeRule(min: 6.3, max: 4808.0),
                CredentialEntryFacilityLengthRule(maxLength: 3600),
            ]
        )
    }
}
