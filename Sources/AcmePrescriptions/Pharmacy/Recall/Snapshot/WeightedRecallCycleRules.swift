import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted recall cycle must pass. Check returns its problems, or none.
    protocol WeightedRecallCycleRule {
        func check(_ item: WeightedRecallCycle) -> [String]
    }

    final class WeightedRecallCycleCodeLengthRule: WeightedRecallCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRecallCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRecallCycleExpiresAtRangeRule: WeightedRecallCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedRecallCycle) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedRecallCycleRequiredClinicianIDRule: WeightedRecallCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRecallCycle) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted recall cycle.
    final class WeightedRecallCycleValidator {
        var rules: [any WeightedRecallCycleRule]

        init(rules: [any WeightedRecallCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRecallCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedRecallCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRecallCycle]) -> [String: [String]] {
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

    static func defaultWeightedRecallCycleValidator() -> WeightedRecallCycleValidator {
        return WeightedRecallCycleValidator(
            rules: [
                WeightedRecallCycleCodeLengthRule(maxLength: 255),
                WeightedRecallCycleExpiresAtRangeRule(min: 255, max: 86400),
                WeightedRecallCycleRequiredClinicianIDRule(message: "weighted recall cycle needs a value"),
            ]
        )
    }
}
