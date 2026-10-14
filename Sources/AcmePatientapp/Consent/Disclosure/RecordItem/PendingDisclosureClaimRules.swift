import AcmePlatform
import Foundation

extension Consent {
    /// A rule a pending disclosure claim must pass. Check returns its problems, or none.
    protocol PendingDisclosureClaimRule {
        func check(_ item: PendingDisclosureClaim) -> [String]
    }

    final class PendingDisclosureClaimRequiredNameRule: PendingDisclosureClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingDisclosureClaim) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingDisclosureClaimCodePrefixRule: PendingDisclosureClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingDisclosureClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingDisclosureClaimCreatedAtRangeRule: PendingDisclosureClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingDisclosureClaim) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingDisclosureClaimEncounterIDLengthRule: PendingDisclosureClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDisclosureClaim) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingDisclosureClaimNameLengthRule: PendingDisclosureClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDisclosureClaim) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingDisclosureClaimDiagnosisCodeLengthRule: PendingDisclosureClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDisclosureClaim) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending disclosure claim.
    final class PendingDisclosureClaimValidator {
        var rules: [any PendingDisclosureClaimRule]

        init(rules: [any PendingDisclosureClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingDisclosureClaim) -> [String] {
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

        func requireValid(_ item: PendingDisclosureClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingDisclosureClaim]) -> [String: [String]] {
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

    static func defaultPendingDisclosureClaimValidator() -> PendingDisclosureClaimValidator {
        return PendingDisclosureClaimValidator(
            rules: [
                PendingDisclosureClaimRequiredNameRule(message: "pending disclosure claim needs an entry"),
                PendingDisclosureClaimCodePrefixRule(prefix: "Q"),
                PendingDisclosureClaimCreatedAtRangeRule(min: 3600, max: 3600),
                PendingDisclosureClaimEncounterIDLengthRule(maxLength: 32),
                PendingDisclosureClaimNameLengthRule(maxLength: 120),
                PendingDisclosureClaimDiagnosisCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
