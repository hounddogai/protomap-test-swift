import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual witness draft must pass. Check returns its problems, or none.
    protocol ManualWitnessDraftRule {
        func check(_ item: ManualWitnessDraft) -> [String]
    }

    final class ManualWitnessDraftGraceDaysRangeRule: ManualWitnessDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualWitnessDraft) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualWitnessDraftRequiredCodeRule: ManualWitnessDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualWitnessDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualWitnessDraftCostRangeRule: ManualWitnessDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualWitnessDraft) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual witness draft.
    final class ManualWitnessDraftValidator {
        var rules: [any ManualWitnessDraftRule]

        init(rules: [any ManualWitnessDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualWitnessDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualWitnessDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualWitnessDraft]) -> [String: [String]] {
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

    static func defaultManualWitnessDraftValidator() -> ManualWitnessDraftValidator {
        return ManualWitnessDraftValidator(
            rules: [
                ManualWitnessDraftGraceDaysRangeRule(min: 64, max: 80),
                ManualWitnessDraftRequiredCodeRule(message: "manual witness draft needs a value"),
                ManualWitnessDraftCostRangeRule(min: 4.5, max: 3391.9),
            ]
        )
    }
}
