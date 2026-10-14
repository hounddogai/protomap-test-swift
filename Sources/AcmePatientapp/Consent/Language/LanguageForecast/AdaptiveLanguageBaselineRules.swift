import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive language baseline must pass. Check returns its problems, or none.
    protocol AdaptiveLanguageBaselineRule {
        func check(_ item: AdaptiveLanguageBaseline) -> [String]
    }

    final class AdaptiveLanguageBaselineRequiredNameRule: AdaptiveLanguageBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveLanguageBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveLanguageBaselineRequiredSpecialtyRule: AdaptiveLanguageBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveLanguageBaseline) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveLanguageBaselineRequiredCodeRule: AdaptiveLanguageBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveLanguageBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveLanguageBaselineAllowedClinicianIDRule: AdaptiveLanguageBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveLanguageBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is duplicated"]
            }
            return []
        }
    }

    final class AdaptiveLanguageBaselineRequiredClinicianIDRule: AdaptiveLanguageBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveLanguageBaseline) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive language baseline.
    final class AdaptiveLanguageBaselineValidator {
        var rules: [any AdaptiveLanguageBaselineRule]

        init(rules: [any AdaptiveLanguageBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveLanguageBaseline) -> [String] {
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

        func requireValid(_ item: AdaptiveLanguageBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveLanguageBaseline]) -> [String: [String]] {
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

    static func defaultAdaptiveLanguageBaselineValidator() -> AdaptiveLanguageBaselineValidator {
        return AdaptiveLanguageBaselineValidator(
            rules: [
                AdaptiveLanguageBaselineRequiredNameRule(message: "adaptive language baseline needs this field"),
                AdaptiveLanguageBaselineRequiredSpecialtyRule(message: "adaptive language baseline needs this field"),
                AdaptiveLanguageBaselineRequiredCodeRule(message: "adaptive language baseline needs a value"),
                AdaptiveLanguageBaselineAllowedClinicianIDRule(allowed: ["rolling", "primary", "primary"]),
                AdaptiveLanguageBaselineRequiredClinicianIDRule(
                    message: "adaptive language baseline needs this field"
                ),
            ]
        )
    }
}
