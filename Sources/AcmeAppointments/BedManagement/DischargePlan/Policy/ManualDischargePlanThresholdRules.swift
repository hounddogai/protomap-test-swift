import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual discharge plan threshold must pass. Check returns its problems, or none.
    protocol ManualDischargePlanThresholdRule {
        func check(_ item: ManualDischargePlanThreshold) -> [String]
    }

    final class ManualDischargePlanThresholdRequiredDiagnosisCodeRule: ManualDischargePlanThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDischargePlanThreshold) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDischargePlanThresholdAmountRangeRule: ManualDischargePlanThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualDischargePlanThreshold) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualDischargePlanThresholdCodeLengthRule: ManualDischargePlanThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDischargePlanThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualDischargePlanThresholdDiagnosisCodeLengthRule: ManualDischargePlanThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDischargePlanThreshold) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual discharge plan threshold.
    final class ManualDischargePlanThresholdValidator {
        var rules: [any ManualDischargePlanThresholdRule]

        init(rules: [any ManualDischargePlanThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualDischargePlanThreshold) -> [String] {
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

        func requireValid(_ item: ManualDischargePlanThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualDischargePlanThreshold]) -> [String: [String]] {
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

    static func defaultManualDischargePlanThresholdValidator() -> ManualDischargePlanThresholdValidator {
        return ManualDischargePlanThresholdValidator(
            rules: [
                ManualDischargePlanThresholdRequiredDiagnosisCodeRule(
                    message: "manual discharge plan threshold needs this field"
                ),
                ManualDischargePlanThresholdAmountRangeRule(min: 5.6, max: 3706.9),
                ManualDischargePlanThresholdCodeLengthRule(maxLength: 32),
                ManualDischargePlanThresholdDiagnosisCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
