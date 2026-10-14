import AcmePlatform
import Foundation

extension Consent {
    /// A rule a global consent form template must pass. Check returns its problems, or none.
    protocol GlobalConsentFormTemplateRule {
        func check(_ item: GlobalConsentFormTemplate) -> [String]
    }

    final class GlobalConsentFormTemplateRequiredCodeRule: GlobalConsentFormTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalConsentFormTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalConsentFormTemplateRequiredPhoneRule: GlobalConsentFormTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalConsentFormTemplate) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalConsentFormTemplateAllowedNameRule: GlobalConsentFormTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalConsentFormTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    final class GlobalConsentFormTemplateCodeLengthRule: GlobalConsentFormTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalConsentFormTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalConsentFormTemplateRequiredClinicianIDRule: GlobalConsentFormTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalConsentFormTemplate) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalConsentFormTemplateRatioRangeRule: GlobalConsentFormTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalConsentFormTemplate) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global consent form template.
    final class GlobalConsentFormTemplateValidator {
        var rules: [any GlobalConsentFormTemplateRule]

        init(rules: [any GlobalConsentFormTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalConsentFormTemplate) -> [String] {
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

        func requireValid(_ item: GlobalConsentFormTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalConsentFormTemplate]) -> [String: [String]] {
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

    static func defaultGlobalConsentFormTemplateValidator() -> GlobalConsentFormTemplateValidator {
        return GlobalConsentFormTemplateValidator(
            rules: [
                GlobalConsentFormTemplateRequiredCodeRule(message: "global consent form template needs this field"),
                GlobalConsentFormTemplateRequiredPhoneRule(message: "global consent form template needs a value"),
                GlobalConsentFormTemplateAllowedNameRule(allowed: ["adaptive", "strict", "batched"]),
                GlobalConsentFormTemplateCodeLengthRule(maxLength: 3600),
                GlobalConsentFormTemplateRequiredClinicianIDRule(
                    message: "global consent form template needs an entry"
                ),
                GlobalConsentFormTemplateRatioRangeRule(min: 4.9, max: 3318.8),
            ]
        )
    }
}
