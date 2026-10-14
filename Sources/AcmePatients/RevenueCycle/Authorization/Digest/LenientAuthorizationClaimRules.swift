import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient authorization claim must pass. Check returns its problems, or none.
    protocol LenientAuthorizationClaimRule {
        func check(_ item: LenientAuthorizationClaim) -> [String]
    }

    final class LenientAuthorizationClaimRequiredEncounterIDRule: LenientAuthorizationClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAuthorizationClaim) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientAuthorizationClaimRequiredSpecialtyRule: LenientAuthorizationClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAuthorizationClaim) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientAuthorizationClaimRefillsRangeRule: LenientAuthorizationClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientAuthorizationClaim) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientAuthorizationClaimEncounterIDLengthRule: LenientAuthorizationClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientAuthorizationClaim) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientAuthorizationClaimRequiredLabelRule: LenientAuthorizationClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAuthorizationClaim) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient authorization claim.
    final class LenientAuthorizationClaimValidator {
        var rules: [any LenientAuthorizationClaimRule]

        init(rules: [any LenientAuthorizationClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientAuthorizationClaim) -> [String] {
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

        func requireValid(_ item: LenientAuthorizationClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientAuthorizationClaim]) -> [String: [String]] {
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

    static func defaultLenientAuthorizationClaimValidator() -> LenientAuthorizationClaimValidator {
        return LenientAuthorizationClaimValidator(
            rules: [
                LenientAuthorizationClaimRequiredEncounterIDRule(
                    message: "lenient authorization claim needs an entry"
                ),
                LenientAuthorizationClaimRequiredSpecialtyRule(message: "lenient authorization claim needs an entry"),
                LenientAuthorizationClaimRefillsRangeRule(min: 64, max: 120),
                LenientAuthorizationClaimEncounterIDLengthRule(maxLength: 32),
                LenientAuthorizationClaimRequiredLabelRule(message: "lenient authorization claim needs a value"),
            ]
        )
    }
}
