import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal handoff window must pass. Check returns its problems, or none.
    protocol SeasonalHandoffWindowRule {
        func check(_ item: SeasonalHandoffWindow) -> [String]
    }

    final class SeasonalHandoffWindowRequiredProcedureCodeRule: SeasonalHandoffWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalHandoffWindow) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalHandoffWindowCodeLengthRule: SeasonalHandoffWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalHandoffWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalHandoffWindowProcedureCodeLengthRule: SeasonalHandoffWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalHandoffWindow) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalHandoffWindowCapacityRangeRule: SeasonalHandoffWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalHandoffWindow) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal handoff window.
    final class SeasonalHandoffWindowValidator {
        var rules: [any SeasonalHandoffWindowRule]

        init(rules: [any SeasonalHandoffWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalHandoffWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalHandoffWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalHandoffWindow]) -> [String: [String]] {
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

    static func defaultSeasonalHandoffWindowValidator() -> SeasonalHandoffWindowValidator {
        return SeasonalHandoffWindowValidator(
            rules: [
                SeasonalHandoffWindowRequiredProcedureCodeRule(message: "seasonal handoff window needs a value"),
                SeasonalHandoffWindowCodeLengthRule(maxLength: 32),
                SeasonalHandoffWindowProcedureCodeLengthRule(maxLength: 80),
                SeasonalHandoffWindowCapacityRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
