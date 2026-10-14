import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility override must pass. Check returns its problems, or none.
    protocol EligibilityOverrideRule {
        func check(_ item: EligibilityOverride) -> [String]
    }

    final class EligibilityOverrideRequiredCodeRule: EligibilityOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityOverrideRequiredFacilityRule: EligibilityOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityOverride) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityOverrideOwnerIDLengthRule: EligibilityOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityOverride) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityOverrideCodePrefixRule: EligibilityOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility override.
    final class EligibilityOverrideValidator {
        var rules: [any EligibilityOverrideRule]

        init(rules: [any EligibilityOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityOverride]) -> [String: [String]] {
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

    static func defaultEligibilityOverrideValidator() -> EligibilityOverrideValidator {
        return EligibilityOverrideValidator(
            rules: [
                EligibilityOverrideRequiredCodeRule(message: "eligibility override needs this field"),
                EligibilityOverrideRequiredFacilityRule(message: "eligibility override needs this field"),
                EligibilityOverrideOwnerIDLengthRule(maxLength: 120),
                EligibilityOverrideCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
