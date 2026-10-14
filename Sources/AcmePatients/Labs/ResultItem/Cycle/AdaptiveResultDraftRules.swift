import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive result draft must pass. Check returns its problems, or none.
    protocol AdaptiveResultDraftRule {
        func check(_ item: AdaptiveResultDraft) -> [String]
    }

    final class AdaptiveResultDraftRequiredLabelRule: AdaptiveResultDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveResultDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveResultDraftDosageMgRangeRule: AdaptiveResultDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveResultDraft) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveResultDraftCopayRangeRule: AdaptiveResultDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveResultDraft) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveResultDraftRequiredExternalRefRule: AdaptiveResultDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveResultDraft) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive result draft.
    final class AdaptiveResultDraftValidator {
        var rules: [any AdaptiveResultDraftRule]

        init(rules: [any AdaptiveResultDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveResultDraft) -> [String] {
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

        func requireValid(_ item: AdaptiveResultDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveResultDraft]) -> [String: [String]] {
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

    static func defaultAdaptiveResultDraftValidator() -> AdaptiveResultDraftValidator {
        return AdaptiveResultDraftValidator(
            rules: [
                AdaptiveResultDraftRequiredLabelRule(message: "adaptive result draft needs a value"),
                AdaptiveResultDraftDosageMgRangeRule(min: 0.7, max: 235.3),
                AdaptiveResultDraftCopayRangeRule(min: 8.9, max: 2076.0),
                AdaptiveResultDraftRequiredExternalRefRule(message: "adaptive result draft needs this field"),
            ]
        )
    }
}
