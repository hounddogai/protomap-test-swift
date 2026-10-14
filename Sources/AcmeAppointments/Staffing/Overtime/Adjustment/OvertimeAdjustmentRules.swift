import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime adjustment must pass. Check returns its problems, or none.
    protocol OvertimeAdjustmentRule {
        func check(_ item: OvertimeAdjustment) -> [String]
    }

    final class OvertimeAdjustmentAllowedRegionRule: OvertimeAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OvertimeAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is duplicated"]
            }
            return []
        }
    }

    final class OvertimeAdjustmentCodeLengthRule: OvertimeAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeAdjustmentRequiredRegionRule: OvertimeAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeAdjustment) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeAdjustmentDurationMinutesRangeRule: OvertimeAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeAdjustment) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OvertimeAdjustmentLabelLengthRule: OvertimeAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime adjustment.
    final class OvertimeAdjustmentValidator {
        var rules: [any OvertimeAdjustmentRule]

        init(rules: [any OvertimeAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeAdjustment]) -> [String: [String]] {
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

    static func defaultOvertimeAdjustmentValidator() -> OvertimeAdjustmentValidator {
        return OvertimeAdjustmentValidator(
            rules: [
                OvertimeAdjustmentAllowedRegionRule(allowed: []),
                OvertimeAdjustmentCodeLengthRule(maxLength: 255),
                OvertimeAdjustmentRequiredRegionRule(message: "overtime adjustment needs an entry"),
                OvertimeAdjustmentDurationMinutesRangeRule(min: 80, max: 80),
                OvertimeAdjustmentLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
