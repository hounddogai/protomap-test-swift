import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a seasonal remittance group must pass. Check returns its problems, or none.
    protocol SeasonalRemittanceGroupRule {
        func check(_ item: SeasonalRemittanceGroup) -> [String]
    }

    final class SeasonalRemittanceGroupAllowedAllergyRule: SeasonalRemittanceGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalRemittanceGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is duplicated"]
            }
            return []
        }
    }

    final class SeasonalRemittanceGroupRequiredCodeRule: SeasonalRemittanceGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRemittanceGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRemittanceGroupCodePrefixRule: SeasonalRemittanceGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalRemittanceGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalRemittanceGroupRequiredAllergyRule: SeasonalRemittanceGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRemittanceGroup) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRemittanceGroupRequiredLabelRule: SeasonalRemittanceGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRemittanceGroup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRemittanceGroupLabelLengthRule: SeasonalRemittanceGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalRemittanceGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal remittance group.
    final class SeasonalRemittanceGroupValidator {
        var rules: [any SeasonalRemittanceGroupRule]

        init(rules: [any SeasonalRemittanceGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalRemittanceGroup) -> [String] {
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

        func requireValid(_ item: SeasonalRemittanceGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalRemittanceGroup]) -> [String: [String]] {
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

    static func defaultSeasonalRemittanceGroupValidator() -> SeasonalRemittanceGroupValidator {
        return SeasonalRemittanceGroupValidator(
            rules: [
                SeasonalRemittanceGroupAllowedAllergyRule(allowed: ["default", "fallback"]),
                SeasonalRemittanceGroupRequiredCodeRule(message: "seasonal remittance group needs an entry"),
                SeasonalRemittanceGroupCodePrefixRule(prefix: "OPS"),
                SeasonalRemittanceGroupRequiredAllergyRule(message: "seasonal remittance group needs an entry"),
                SeasonalRemittanceGroupRequiredLabelRule(message: "seasonal remittance group needs a value"),
                SeasonalRemittanceGroupLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
