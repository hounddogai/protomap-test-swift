import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual alert metric must pass. Check returns its problems, or none.
    protocol ManualAlertMetricRule {
        func check(_ item: ManualAlertMetric) -> [String]
    }

    final class ManualAlertMetricRequiredCodeRule: ManualAlertMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAlertMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualAlertMetricCodeLengthRule: ManualAlertMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualAlertMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualAlertMetricProcedureCodeLengthRule: ManualAlertMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualAlertMetric) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualAlertMetricSpecialtyLengthRule: ManualAlertMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualAlertMetric) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualAlertMetricActiveGuardRule: ManualAlertMetricRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ManualAlertMetric) -> [String] {
            if item.active && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ManualAlertMetricAllowedProcedureCodeRule: ManualAlertMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualAlertMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a manual alert metric.
    final class ManualAlertMetricValidator {
        var rules: [any ManualAlertMetricRule]

        init(rules: [any ManualAlertMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualAlertMetric) -> [String] {
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

        func requireValid(_ item: ManualAlertMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualAlertMetric]) -> [String: [String]] {
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

    static func defaultManualAlertMetricValidator() -> ManualAlertMetricValidator {
        return ManualAlertMetricValidator(
            rules: [
                ManualAlertMetricRequiredCodeRule(message: "manual alert metric needs this field"),
                ManualAlertMetricCodeLengthRule(maxLength: 120),
                ManualAlertMetricProcedureCodeLengthRule(maxLength: 80),
                ManualAlertMetricSpecialtyLengthRule(maxLength: 1000),
                ManualAlertMetricActiveGuardRule(limit: 9.2),
                ManualAlertMetricAllowedProcedureCodeRule(allowed: ["capped", "fallback"]),
            ]
        )
    }
}
