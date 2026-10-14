import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted charge tier must pass. Check returns its problems, or none.
    protocol WeightedChargeTierRule {
        func check(_ item: WeightedChargeTier) -> [String]
    }

    final class WeightedChargeTierFacilityLengthRule: WeightedChargeTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedChargeTier) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedChargeTierRequiredNameRule: WeightedChargeTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedChargeTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedChargeTierAttemptsRangeRule: WeightedChargeTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedChargeTier) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedChargeTierCodeLengthRule: WeightedChargeTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedChargeTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted charge tier.
    final class WeightedChargeTierValidator {
        var rules: [any WeightedChargeTierRule]

        init(rules: [any WeightedChargeTierRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedChargeTier) -> [String] {
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

        func requireValid(_ item: WeightedChargeTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedChargeTier]) -> [String: [String]] {
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

    static func defaultWeightedChargeTierValidator() -> WeightedChargeTierValidator {
        return WeightedChargeTierValidator(
            rules: [
                WeightedChargeTierFacilityLengthRule(maxLength: 16),
                WeightedChargeTierRequiredNameRule(message: "weighted charge tier needs this field"),
                WeightedChargeTierAttemptsRangeRule(min: 255, max: 255),
                WeightedChargeTierCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
