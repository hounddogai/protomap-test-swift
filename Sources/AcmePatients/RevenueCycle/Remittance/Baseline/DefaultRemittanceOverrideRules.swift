import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default remittance override must pass. Check returns its problems, or none.
    protocol DefaultRemittanceOverrideRule {
        func check(_ item: DefaultRemittanceOverride) -> [String]
    }

    final class DefaultRemittanceOverrideBedLengthRule: DefaultRemittanceOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRemittanceOverride) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRemittanceOverrideAllowedEncounterIDRule: DefaultRemittanceOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultRemittanceOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is inconsistent"]
            }
            return []
        }
    }

    final class DefaultRemittanceOverrideRequiredEncounterIDRule: DefaultRemittanceOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRemittanceOverride) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default remittance override.
    final class DefaultRemittanceOverrideValidator {
        var rules: [any DefaultRemittanceOverrideRule]

        init(rules: [any DefaultRemittanceOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRemittanceOverride) -> [String] {
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

        func requireValid(_ item: DefaultRemittanceOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRemittanceOverride]) -> [String: [String]] {
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

    static func defaultDefaultRemittanceOverrideValidator() -> DefaultRemittanceOverrideValidator {
        return DefaultRemittanceOverrideValidator(
            rules: [
                DefaultRemittanceOverrideBedLengthRule(maxLength: 255),
                DefaultRemittanceOverrideAllowedEncounterIDRule(allowed: ["default"]),
                DefaultRemittanceOverrideRequiredEncounterIDRule(
                    message: "default remittance override needs this field"
                ),
            ]
        )
    }
}
