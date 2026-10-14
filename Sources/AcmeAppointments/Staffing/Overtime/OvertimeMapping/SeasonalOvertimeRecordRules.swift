import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal overtime record must pass. Check returns its problems, or none.
    protocol SeasonalOvertimeRecordRule {
        func check(_ item: SeasonalOvertimeRecord) -> [String]
    }

    final class SeasonalOvertimeRecordRequiredLabelRule: SeasonalOvertimeRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalOvertimeRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalOvertimeRecordCodePrefixRule: SeasonalOvertimeRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalOvertimeRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalOvertimeRecordRequiredCodeRule: SeasonalOvertimeRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalOvertimeRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal overtime record.
    final class SeasonalOvertimeRecordValidator {
        var rules: [any SeasonalOvertimeRecordRule]

        init(rules: [any SeasonalOvertimeRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalOvertimeRecord) -> [String] {
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

        func requireValid(_ item: SeasonalOvertimeRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalOvertimeRecord]) -> [String: [String]] {
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

    static func defaultSeasonalOvertimeRecordValidator() -> SeasonalOvertimeRecordValidator {
        return SeasonalOvertimeRecordValidator(
            rules: [
                SeasonalOvertimeRecordRequiredLabelRule(message: "seasonal overtime record needs a value"),
                SeasonalOvertimeRecordCodePrefixRule(prefix: "Q"),
                SeasonalOvertimeRecordRequiredCodeRule(message: "seasonal overtime record needs a value"),
            ]
        )
    }
}
