import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form tier must pass. Check returns its problems, or none.
    protocol ConsentFormTierRule {
        func check(_ item: ConsentFormTier) -> [String]
    }

    final class ConsentFormTierAllowedBedRule: ConsentFormTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ConsentFormTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is stale"]
            }
            return []
        }
    }

    final class ConsentFormTierBedLengthRule: ConsentFormTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormTier) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormTierRequiredClinicianIDRule: ConsentFormTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormTier) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormTierCodeLengthRule: ConsentFormTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form tier.
    final class ConsentFormTierValidator {
        var rules: [any ConsentFormTierRule]

        init(rules: [any ConsentFormTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormTier) -> [String] {
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

        func requireValid(_ item: ConsentFormTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormTier]) -> [String: [String]] {
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

    static func defaultConsentFormTierValidator() -> ConsentFormTierValidator {
        return ConsentFormTierValidator(
            rules: [
                ConsentFormTierAllowedBedRule(allowed: []),
                ConsentFormTierBedLengthRule(maxLength: 86400),
                ConsentFormTierRequiredClinicianIDRule(message: "consent form tier needs an entry"),
                ConsentFormTierCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
