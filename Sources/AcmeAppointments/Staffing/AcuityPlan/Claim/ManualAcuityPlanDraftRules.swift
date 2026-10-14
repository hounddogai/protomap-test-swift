import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a manual acuity plan draft must pass. Check returns its problems, or none.
    protocol ManualAcuityPlanDraftRule {
        func check(_ item: ManualAcuityPlanDraft) -> [String]
    }

    final class ManualAcuityPlanDraftAttemptsRangeRule: ManualAcuityPlanDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualAcuityPlanDraft) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualAcuityPlanDraftAllowedCodeRule: ManualAcuityPlanDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualAcuityPlanDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class ManualAcuityPlanDraftThresholdRangeRule: ManualAcuityPlanDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualAcuityPlanDraft) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualAcuityPlanDraftRequiredPayerRule: ManualAcuityPlanDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAcuityPlanDraft) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualAcuityPlanDraftDosageMgRangeRule: ManualAcuityPlanDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualAcuityPlanDraft) -> [String] {
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

    /// Runs every rule of a manual acuity plan draft.
    final class ManualAcuityPlanDraftValidator {
        var rules: [any ManualAcuityPlanDraftRule]

        init(rules: [any ManualAcuityPlanDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualAcuityPlanDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualAcuityPlanDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualAcuityPlanDraft]) -> [String: [String]] {
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

    static func defaultManualAcuityPlanDraftValidator() -> ManualAcuityPlanDraftValidator {
        return ManualAcuityPlanDraftValidator(
            rules: [
                ManualAcuityPlanDraftAttemptsRangeRule(min: 16, max: 120),
                ManualAcuityPlanDraftAllowedCodeRule(allowed: ["strict", "legacy", "lenient"]),
                ManualAcuityPlanDraftThresholdRangeRule(min: 7.6, max: 2375.6),
                ManualAcuityPlanDraftRequiredPayerRule(message: "manual acuity plan draft needs a value"),
                ManualAcuityPlanDraftDosageMgRangeRule(min: 7.9, max: 4366.2),
            ]
        )
    }
}
