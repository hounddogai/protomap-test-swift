import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan budget must pass. Check returns its problems, or none.
    protocol DischargePlanBudgetRule {
        func check(_ item: DischargePlanBudget) -> [String]
    }

    final class DischargePlanBudgetAllowedCurrencyRule: DischargePlanBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is below minimum"]
            }
            return []
        }
    }

    final class DischargePlanBudgetCodeLengthRule: DischargePlanBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanBudgetClinicianIDLengthRule: DischargePlanBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanBudget) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanBudgetPinnedGuardRule: DischargePlanBudgetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DischargePlanBudget) -> [String] {
            if item.pinned && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class DischargePlanBudgetTitleLengthRule: DischargePlanBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanBudgetRequiredClinicianIDRule: DischargePlanBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanBudget) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan budget.
    final class DischargePlanBudgetValidator {
        var rules: [any DischargePlanBudgetRule]

        init(rules: [any DischargePlanBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanBudget]) -> [String: [String]] {
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

    static func defaultDischargePlanBudgetValidator() -> DischargePlanBudgetValidator {
        return DischargePlanBudgetValidator(
            rules: [
                DischargePlanBudgetAllowedCurrencyRule(allowed: ["global"]),
                DischargePlanBudgetCodeLengthRule(maxLength: 255),
                DischargePlanBudgetClinicianIDLengthRule(maxLength: 80),
                DischargePlanBudgetPinnedGuardRule(limit: 86400),
                DischargePlanBudgetTitleLengthRule(maxLength: 86400),
                DischargePlanBudgetRequiredClinicianIDRule(message: "discharge plan budget needs an entry"),
            ]
        )
    }
}
