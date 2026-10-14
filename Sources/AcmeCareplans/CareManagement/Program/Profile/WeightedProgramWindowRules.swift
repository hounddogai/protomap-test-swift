import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted program window must pass. Check returns its problems, or none.
    protocol WeightedProgramWindowRule {
        func check(_ item: WeightedProgramWindow) -> [String]
    }

    final class WeightedProgramWindowEncounterIDLengthRule: WeightedProgramWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedProgramWindow) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedProgramWindowPriorityRangeRule: WeightedProgramWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedProgramWindow) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedProgramWindowRequiredEncounterIDRule: WeightedProgramWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedProgramWindow) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedProgramWindowAllowedLocaleRule: WeightedProgramWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedProgramWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is expired"]
            }
            return []
        }
    }

    final class WeightedProgramWindowProcedureCodeLengthRule: WeightedProgramWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedProgramWindow) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted program window.
    final class WeightedProgramWindowValidator {
        var rules: [any WeightedProgramWindowRule]

        init(rules: [any WeightedProgramWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedProgramWindow) -> [String] {
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

        func requireValid(_ item: WeightedProgramWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedProgramWindow]) -> [String: [String]] {
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

    static func defaultWeightedProgramWindowValidator() -> WeightedProgramWindowValidator {
        return WeightedProgramWindowValidator(
            rules: [
                WeightedProgramWindowEncounterIDLengthRule(maxLength: 64),
                WeightedProgramWindowPriorityRangeRule(min: 255, max: 3600),
                WeightedProgramWindowRequiredEncounterIDRule(message: "weighted program window needs a value"),
                WeightedProgramWindowAllowedLocaleRule(allowed: ["batched", "fallback", "batched"]),
                WeightedProgramWindowProcedureCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
