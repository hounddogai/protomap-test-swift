import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional overtime window must pass. Check returns its problems, or none.
    protocol RegionalOvertimeWindowRule {
        func check(_ item: RegionalOvertimeWindow) -> [String]
    }

    final class RegionalOvertimeWindowRequiredProcedureCodeRule: RegionalOvertimeWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOvertimeWindow) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalOvertimeWindowBatchSizeRangeRule: RegionalOvertimeWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalOvertimeWindow) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalOvertimeWindowProcedureCodeLengthRule: RegionalOvertimeWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOvertimeWindow) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOvertimeWindowActiveGuardRule: RegionalOvertimeWindowRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RegionalOvertimeWindow) -> [String] {
            if item.active && (item.durationMinutes > limit) {
                return ["duration minutes \(item.durationMinutes) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a regional overtime window.
    final class RegionalOvertimeWindowValidator {
        var rules: [any RegionalOvertimeWindowRule]

        init(rules: [any RegionalOvertimeWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalOvertimeWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalOvertimeWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalOvertimeWindow]) -> [String: [String]] {
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

    static func defaultRegionalOvertimeWindowValidator() -> RegionalOvertimeWindowValidator {
        return RegionalOvertimeWindowValidator(
            rules: [
                RegionalOvertimeWindowRequiredProcedureCodeRule(message: "regional overtime window needs a value"),
                RegionalOvertimeWindowBatchSizeRangeRule(min: 80, max: 1000),
                RegionalOvertimeWindowProcedureCodeLengthRule(maxLength: 1000),
                RegionalOvertimeWindowActiveGuardRule(limit: 64),
            ]
        )
    }
}
