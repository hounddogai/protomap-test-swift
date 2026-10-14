import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global acuity plan exception must pass. Check returns its problems, or none.
    protocol GlobalAcuityPlanExceptionRule {
        func check(_ item: GlobalAcuityPlanException) -> [String]
    }

    final class GlobalAcuityPlanExceptionRequiredCodeRule: GlobalAcuityPlanExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAcuityPlanException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAcuityPlanExceptionAllergyLengthRule: GlobalAcuityPlanExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAcuityPlanException) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAcuityPlanExceptionRequiredContactEmailRule: GlobalAcuityPlanExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAcuityPlanException) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAcuityPlanExceptionCostRangeRule: GlobalAcuityPlanExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalAcuityPlanException) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalAcuityPlanExceptionTitleLengthRule: GlobalAcuityPlanExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAcuityPlanException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global acuity plan exception.
    final class GlobalAcuityPlanExceptionValidator {
        var rules: [any GlobalAcuityPlanExceptionRule]

        init(rules: [any GlobalAcuityPlanExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAcuityPlanException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalAcuityPlanException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAcuityPlanException]) -> [String: [String]] {
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

    static func defaultGlobalAcuityPlanExceptionValidator() -> GlobalAcuityPlanExceptionValidator {
        return GlobalAcuityPlanExceptionValidator(
            rules: [
                GlobalAcuityPlanExceptionRequiredCodeRule(message: "global acuity plan exception needs an entry"),
                GlobalAcuityPlanExceptionAllergyLengthRule(maxLength: 120),
                GlobalAcuityPlanExceptionRequiredContactEmailRule(
                    message: "global acuity plan exception needs an entry"
                ),
                GlobalAcuityPlanExceptionCostRangeRule(min: 8.4, max: 4397.4),
                GlobalAcuityPlanExceptionTitleLengthRule(maxLength: 120),
            ]
        )
    }
}
