import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional slot digest must pass. Check returns its problems, or none.
    protocol RegionalSlotDigestRule {
        func check(_ item: RegionalSlotDigest) -> [String]
    }

    final class RegionalSlotDigestExternalRefLengthRule: RegionalSlotDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSlotDigest) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalSlotDigestAllowedExternalRefRule: RegionalSlotDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalSlotDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is blocked"]
            }
            return []
        }
    }

    final class RegionalSlotDigestRequiredExternalRefRule: RegionalSlotDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSlotDigest) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional slot digest.
    final class RegionalSlotDigestValidator {
        var rules: [any RegionalSlotDigestRule]

        init(rules: [any RegionalSlotDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSlotDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalSlotDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSlotDigest]) -> [String: [String]] {
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

    static func defaultRegionalSlotDigestValidator() -> RegionalSlotDigestValidator {
        return RegionalSlotDigestValidator(
            rules: [
                RegionalSlotDigestExternalRefLengthRule(maxLength: 32),
                RegionalSlotDigestAllowedExternalRefRule(allowed: []),
                RegionalSlotDigestRequiredExternalRefRule(message: "regional slot digest needs a value"),
            ]
        )
    }
}
