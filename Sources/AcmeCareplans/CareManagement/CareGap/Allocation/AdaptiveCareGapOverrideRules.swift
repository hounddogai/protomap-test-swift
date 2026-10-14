import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive care gap override must pass. Check returns its problems, or none.
    protocol AdaptiveCareGapOverrideRule {
        func check(_ item: AdaptiveCareGapOverride) -> [String]
    }

    final class AdaptiveCareGapOverrideContactEmailLengthRule: AdaptiveCareGapOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCareGapOverride) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCareGapOverrideCodeLengthRule: AdaptiveCareGapOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCareGapOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCareGapOverrideRequiredCurrencyRule: AdaptiveCareGapOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCareGapOverride) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCareGapOverrideRequiredCodeRule: AdaptiveCareGapOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCareGapOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive care gap override.
    final class AdaptiveCareGapOverrideValidator {
        var rules: [any AdaptiveCareGapOverrideRule]

        init(rules: [any AdaptiveCareGapOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCareGapOverride) -> [String] {
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

        func requireValid(_ item: AdaptiveCareGapOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCareGapOverride]) -> [String: [String]] {
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

    static func defaultAdaptiveCareGapOverrideValidator() -> AdaptiveCareGapOverrideValidator {
        return AdaptiveCareGapOverrideValidator(
            rules: [
                AdaptiveCareGapOverrideContactEmailLengthRule(maxLength: 16),
                AdaptiveCareGapOverrideCodeLengthRule(maxLength: 64),
                AdaptiveCareGapOverrideRequiredCurrencyRule(message: "adaptive care gap override needs this field"),
                AdaptiveCareGapOverrideRequiredCodeRule(message: "adaptive care gap override needs this field"),
            ]
        )
    }
}
