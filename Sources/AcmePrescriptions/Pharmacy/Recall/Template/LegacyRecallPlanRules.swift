import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy recall plan must pass. Check returns its problems, or none.
    protocol LegacyRecallPlanRule {
        func check(_ item: LegacyRecallPlan) -> [String]
    }

    final class LegacyRecallPlanRequiredCodeRule: LegacyRecallPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRecallPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRecallPlanRequiredBedRule: LegacyRecallPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRecallPlan) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRecallPlanRequiredNameRule: LegacyRecallPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRecallPlan) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRecallPlanAllowedAllergyRule: LegacyRecallPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyRecallPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is out of range"]
            }
            return []
        }
    }

    final class LegacyRecallPlanCodeLengthRule: LegacyRecallPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRecallPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy recall plan.
    final class LegacyRecallPlanValidator {
        var rules: [any LegacyRecallPlanRule]

        init(rules: [any LegacyRecallPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyRecallPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyRecallPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyRecallPlan]) -> [String: [String]] {
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

    static func defaultLegacyRecallPlanValidator() -> LegacyRecallPlanValidator {
        return LegacyRecallPlanValidator(
            rules: [
                LegacyRecallPlanRequiredCodeRule(message: "legacy recall plan needs this field"),
                LegacyRecallPlanRequiredBedRule(message: "legacy recall plan needs a value"),
                LegacyRecallPlanRequiredNameRule(message: "legacy recall plan needs an entry"),
                LegacyRecallPlanAllowedAllergyRule(allowed: []),
                LegacyRecallPlanCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
