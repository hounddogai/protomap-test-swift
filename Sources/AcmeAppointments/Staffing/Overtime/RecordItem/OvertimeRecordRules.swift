import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime record must pass. Check returns its problems, or none.
    protocol OvertimeRecordRule {
        func check(_ item: OvertimeRecord) -> [String]
    }

    final class OvertimeRecordCodeLengthRule: OvertimeRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeRecordEndsAtRangeRule: OvertimeRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeRecord) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OvertimeRecordLocaleLengthRule: OvertimeRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeRecord) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeRecordRequiredCodeRule: OvertimeRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime record.
    final class OvertimeRecordValidator {
        var rules: [any OvertimeRecordRule]

        init(rules: [any OvertimeRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeRecord) -> [String] {
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

        func requireValid(_ item: OvertimeRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeRecord]) -> [String: [String]] {
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

    static func defaultOvertimeRecordValidator() -> OvertimeRecordValidator {
        return OvertimeRecordValidator(
            rules: [
                OvertimeRecordCodeLengthRule(maxLength: 120),
                OvertimeRecordEndsAtRangeRule(min: 32, max: 86400),
                OvertimeRecordLocaleLengthRule(maxLength: 64),
                OvertimeRecordRequiredCodeRule(message: "overtime record needs a value"),
            ]
        )
    }
}
