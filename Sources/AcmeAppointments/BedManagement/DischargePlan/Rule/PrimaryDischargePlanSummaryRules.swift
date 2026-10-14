import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary discharge plan summary must pass. Check returns its problems, or none.
    protocol PrimaryDischargePlanSummaryRule {
        func check(_ item: PrimaryDischargePlanSummary) -> [String]
    }

    final class PrimaryDischargePlanSummaryThresholdRangeRule: PrimaryDischargePlanSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDischargePlanSummary) -> [String] {
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

    final class PrimaryDischargePlanSummaryFloorValueRangeRule: PrimaryDischargePlanSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDischargePlanSummary) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryDischargePlanSummaryUnitLengthRule: PrimaryDischargePlanSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDischargePlanSummary) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDischargePlanSummaryCopayRangeRule: PrimaryDischargePlanSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryDischargePlanSummary) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryDischargePlanSummaryCodePrefixRule: PrimaryDischargePlanSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryDischargePlanSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryDischargePlanSummaryCodeLengthRule: PrimaryDischargePlanSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDischargePlanSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary discharge plan summary.
    final class PrimaryDischargePlanSummaryValidator {
        var rules: [any PrimaryDischargePlanSummaryRule]

        init(rules: [any PrimaryDischargePlanSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryDischargePlanSummary) -> [String] {
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

        func requireValid(_ item: PrimaryDischargePlanSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryDischargePlanSummary]) -> [String: [String]] {
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

    static func defaultPrimaryDischargePlanSummaryValidator() -> PrimaryDischargePlanSummaryValidator {
        return PrimaryDischargePlanSummaryValidator(
            rules: [
                PrimaryDischargePlanSummaryThresholdRangeRule(min: 3.6, max: 4100.3),
                PrimaryDischargePlanSummaryFloorValueRangeRule(min: 4.9, max: 2169.5),
                PrimaryDischargePlanSummaryUnitLengthRule(maxLength: 80),
                PrimaryDischargePlanSummaryCopayRangeRule(min: 5.5, max: 3381.3),
                PrimaryDischargePlanSummaryCodePrefixRule(prefix: "X"),
                PrimaryDischargePlanSummaryCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
