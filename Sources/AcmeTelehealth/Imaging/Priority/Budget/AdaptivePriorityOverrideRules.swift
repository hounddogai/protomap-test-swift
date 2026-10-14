import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive priority override must pass. Check returns its problems, or none.
    protocol AdaptivePriorityOverrideRule {
        func check(_ item: AdaptivePriorityOverride) -> [String]
    }

    final class AdaptivePriorityOverrideRequiredPatientRefRule: AdaptivePriorityOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePriorityOverride) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePriorityOverrideRequiredSourceRule: AdaptivePriorityOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePriorityOverride) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePriorityOverrideRequiredLabelRule: AdaptivePriorityOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePriorityOverride) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePriorityOverrideAllowedPatientRefRule: AdaptivePriorityOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptivePriorityOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive priority override.
    final class AdaptivePriorityOverrideValidator {
        var rules: [any AdaptivePriorityOverrideRule]

        init(rules: [any AdaptivePriorityOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptivePriorityOverride) -> [String] {
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

        func requireValid(_ item: AdaptivePriorityOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptivePriorityOverride]) -> [String: [String]] {
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

    static func defaultAdaptivePriorityOverrideValidator() -> AdaptivePriorityOverrideValidator {
        return AdaptivePriorityOverrideValidator(
            rules: [
                AdaptivePriorityOverrideRequiredPatientRefRule(message: "adaptive priority override needs an entry"),
                AdaptivePriorityOverrideRequiredSourceRule(message: "adaptive priority override needs this field"),
                AdaptivePriorityOverrideRequiredLabelRule(message: "adaptive priority override needs this field"),
                AdaptivePriorityOverrideAllowedPatientRefRule(allowed: []),
            ]
        )
    }
}
