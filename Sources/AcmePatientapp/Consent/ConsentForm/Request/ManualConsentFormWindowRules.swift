import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual consent form window must pass. Check returns its problems, or none.
    protocol ManualConsentFormWindowRule {
        func check(_ item: ManualConsentFormWindow) -> [String]
    }

    final class ManualConsentFormWindowAllowedContactEmailRule: ManualConsentFormWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualConsentFormWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is blocked"]
            }
            return []
        }
    }

    final class ManualConsentFormWindowRatioRangeRule: ManualConsentFormWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualConsentFormWindow) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualConsentFormWindowRequiredTitleRule: ManualConsentFormWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualConsentFormWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual consent form window.
    final class ManualConsentFormWindowValidator {
        var rules: [any ManualConsentFormWindowRule]

        init(rules: [any ManualConsentFormWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualConsentFormWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualConsentFormWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualConsentFormWindow]) -> [String: [String]] {
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

    static func defaultManualConsentFormWindowValidator() -> ManualConsentFormWindowValidator {
        return ManualConsentFormWindowValidator(
            rules: [
                ManualConsentFormWindowAllowedContactEmailRule(allowed: ["primary", "rolling", "rolling"]),
                ManualConsentFormWindowRatioRangeRule(min: 5.9, max: 4432.8),
                ManualConsentFormWindowRequiredTitleRule(message: "manual consent form window needs this field"),
            ]
        )
    }
}
