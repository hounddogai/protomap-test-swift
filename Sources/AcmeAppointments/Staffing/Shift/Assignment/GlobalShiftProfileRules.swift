import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global shift profile must pass. Check returns its problems, or none.
    protocol GlobalShiftProfileRule {
        func check(_ item: GlobalShiftProfile) -> [String]
    }

    final class GlobalShiftProfileCodeLengthRule: GlobalShiftProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalShiftProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalShiftProfileEncounterIDLengthRule: GlobalShiftProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalShiftProfile) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalShiftProfileScoreRangeRule: GlobalShiftProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalShiftProfile) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalShiftProfileRequiredFacilityRule: GlobalShiftProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalShiftProfile) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global shift profile.
    final class GlobalShiftProfileValidator {
        var rules: [any GlobalShiftProfileRule]

        init(rules: [any GlobalShiftProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalShiftProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalShiftProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalShiftProfile]) -> [String: [String]] {
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

    static func defaultGlobalShiftProfileValidator() -> GlobalShiftProfileValidator {
        return GlobalShiftProfileValidator(
            rules: [
                GlobalShiftProfileCodeLengthRule(maxLength: 86400),
                GlobalShiftProfileEncounterIDLengthRule(maxLength: 86400),
                GlobalShiftProfileScoreRangeRule(min: 5.4, max: 2454.4),
                GlobalShiftProfileRequiredFacilityRule(message: "global shift profile needs this field"),
            ]
        )
    }
}
