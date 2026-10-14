import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert record must pass. Check returns its problems, or none.
    protocol AlertRecordRule {
        func check(_ item: AlertRecord) -> [String]
    }

    final class AlertRecordAllowedProcedureCodeRule: AlertRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AlertRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is expired"]
            }
            return []
        }
    }

    final class AlertRecordMaximumRangeRule: AlertRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertRecord) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AlertRecordThresholdRangeRule: AlertRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertRecord) -> [String] {
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

    /// Runs every rule of a alert record.
    final class AlertRecordValidator {
        var rules: [any AlertRecordRule]

        init(rules: [any AlertRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertRecord) -> [String] {
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

        func requireValid(_ item: AlertRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertRecord]) -> [String: [String]] {
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

    static func defaultAlertRecordValidator() -> AlertRecordValidator {
        return AlertRecordValidator(
            rules: [
                AlertRecordAllowedProcedureCodeRule(allowed: ["fallback", "strict"]),
                AlertRecordMaximumRangeRule(min: 8.0, max: 1214.3),
                AlertRecordThresholdRangeRule(min: 3.9, max: 3550.9),
            ]
        )
    }
}
