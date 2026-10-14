import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient substitution claim must pass. Check returns its problems, or none.
    protocol LenientSubstitutionClaimRule {
        func check(_ item: LenientSubstitutionClaim) -> [String]
    }

    final class LenientSubstitutionClaimCodeLengthRule: LenientSubstitutionClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientSubstitutionClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientSubstitutionClaimRequiredNameRule: LenientSubstitutionClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientSubstitutionClaim) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientSubstitutionClaimLocaleLengthRule: LenientSubstitutionClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientSubstitutionClaim) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient substitution claim.
    final class LenientSubstitutionClaimValidator {
        var rules: [any LenientSubstitutionClaimRule]

        init(rules: [any LenientSubstitutionClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientSubstitutionClaim) -> [String] {
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

        func requireValid(_ item: LenientSubstitutionClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientSubstitutionClaim]) -> [String: [String]] {
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

    static func defaultLenientSubstitutionClaimValidator() -> LenientSubstitutionClaimValidator {
        return LenientSubstitutionClaimValidator(
            rules: [
                LenientSubstitutionClaimCodeLengthRule(maxLength: 80),
                LenientSubstitutionClaimRequiredNameRule(message: "lenient substitution claim needs a value"),
                LenientSubstitutionClaimLocaleLengthRule(maxLength: 1000),
            ]
        )
    }
}
