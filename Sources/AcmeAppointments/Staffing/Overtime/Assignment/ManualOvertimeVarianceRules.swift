import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a manual overtime variance must pass. Check returns its problems, or none.
    protocol ManualOvertimeVarianceRule {
        func check(_ item: ManualOvertimeVariance) -> [String]
    }

    final class ManualOvertimeVarianceAllowedLabelRule: ManualOvertimeVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualOvertimeVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class ManualOvertimeVarianceActiveGuardRule: ManualOvertimeVarianceRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ManualOvertimeVariance) -> [String] {
            if item.active && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ManualOvertimeVarianceRequiredLabelRule: ManualOvertimeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualOvertimeVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual overtime variance.
    final class ManualOvertimeVarianceValidator {
        var rules: [any ManualOvertimeVarianceRule]

        init(rules: [any ManualOvertimeVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualOvertimeVariance) -> [String] {
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

        func requireValid(_ item: ManualOvertimeVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualOvertimeVariance]) -> [String: [String]] {
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

    static func defaultManualOvertimeVarianceValidator() -> ManualOvertimeVarianceValidator {
        return ManualOvertimeVarianceValidator(
            rules: [
                ManualOvertimeVarianceAllowedLabelRule(allowed: ["manual"]),
                ManualOvertimeVarianceActiveGuardRule(limit: 3600),
                ManualOvertimeVarianceRequiredLabelRule(message: "manual overtime variance needs an entry"),
            ]
        )
    }
}
