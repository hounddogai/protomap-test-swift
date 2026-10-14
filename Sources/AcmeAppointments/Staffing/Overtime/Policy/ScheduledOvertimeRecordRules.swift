import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled overtime record must pass. Check returns its problems, or none.
    protocol ScheduledOvertimeRecordRule {
        func check(_ item: ScheduledOvertimeRecord) -> [String]
    }

    final class ScheduledOvertimeRecordAllowedLabelRule: ScheduledOvertimeRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledOvertimeRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    final class ScheduledOvertimeRecordRatioRangeRule: ScheduledOvertimeRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledOvertimeRecord) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledOvertimeRecordRequiredFacilityRule: ScheduledOvertimeRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledOvertimeRecord) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledOvertimeRecordRequiredCodeRule: ScheduledOvertimeRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledOvertimeRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledOvertimeRecordCodePrefixRule: ScheduledOvertimeRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledOvertimeRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled overtime record.
    final class ScheduledOvertimeRecordValidator {
        var rules: [any ScheduledOvertimeRecordRule]

        init(rules: [any ScheduledOvertimeRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledOvertimeRecord) -> [String] {
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

        func requireValid(_ item: ScheduledOvertimeRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledOvertimeRecord]) -> [String: [String]] {
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

    static func defaultScheduledOvertimeRecordValidator() -> ScheduledOvertimeRecordValidator {
        return ScheduledOvertimeRecordValidator(
            rules: [
                ScheduledOvertimeRecordAllowedLabelRule(allowed: ["strict", "legacy"]),
                ScheduledOvertimeRecordRatioRangeRule(min: 6.2, max: 2416.9),
                ScheduledOvertimeRecordRequiredFacilityRule(message: "scheduled overtime record needs a value"),
                ScheduledOvertimeRecordRequiredCodeRule(message: "scheduled overtime record needs this field"),
                ScheduledOvertimeRecordCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
