import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense adjustment must pass. Check returns its problems, or none.
    protocol DispenseAdjustmentRule {
        func check(_ item: DispenseAdjustment) -> [String]
    }

    final class DispenseAdjustmentCodePrefixRule: DispenseAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DispenseAdjustmentRequiredNameRule: DispenseAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseAdjustment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseAdjustmentRequiredCodeRule: DispenseAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseAdjustmentEndsAtRangeRule: DispenseAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseAdjustment) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a dispense adjustment.
    final class DispenseAdjustmentValidator {
        var rules: [any DispenseAdjustmentRule]

        init(rules: [any DispenseAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseAdjustment) -> [String] {
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

        func requireValid(_ item: DispenseAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseAdjustment]) -> [String: [String]] {
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

    static func defaultDispenseAdjustmentValidator() -> DispenseAdjustmentValidator {
        return DispenseAdjustmentValidator(
            rules: [
                DispenseAdjustmentCodePrefixRule(prefix: "X"),
                DispenseAdjustmentRequiredNameRule(message: "dispense adjustment needs a value"),
                DispenseAdjustmentRequiredCodeRule(message: "dispense adjustment needs a value"),
                DispenseAdjustmentEndsAtRangeRule(min: 16, max: 32),
            ]
        )
    }
}
