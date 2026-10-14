import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a strict dispense request must pass. Check returns its problems, or none.
    protocol StrictDispenseRequestRule {
        func check(_ item: StrictDispenseRequest) -> [String]
    }

    final class StrictDispenseRequestRequiredTitleRule: StrictDispenseRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictDispenseRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictDispenseRequestAllowedLocaleRule: StrictDispenseRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictDispenseRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is below minimum"]
            }
            return []
        }
    }

    final class StrictDispenseRequestCopayRangeRule: StrictDispenseRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictDispenseRequest) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictDispenseRequestCostRangeRule: StrictDispenseRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictDispenseRequest) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictDispenseRequestCodeLengthRule: StrictDispenseRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictDispenseRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictDispenseRequestUnitLengthRule: StrictDispenseRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictDispenseRequest) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict dispense request.
    final class StrictDispenseRequestValidator {
        var rules: [any StrictDispenseRequestRule]

        init(rules: [any StrictDispenseRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictDispenseRequest) -> [String] {
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

        func requireValid(_ item: StrictDispenseRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictDispenseRequest]) -> [String: [String]] {
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

    static func defaultStrictDispenseRequestValidator() -> StrictDispenseRequestValidator {
        return StrictDispenseRequestValidator(
            rules: [
                StrictDispenseRequestRequiredTitleRule(message: "strict dispense request needs this field"),
                StrictDispenseRequestAllowedLocaleRule(allowed: ["weighted", "seasonal", "seasonal"]),
                StrictDispenseRequestCopayRangeRule(min: 4.3, max: 457.2),
                StrictDispenseRequestCostRangeRule(min: 1.4, max: 4356.6),
                StrictDispenseRequestCodeLengthRule(maxLength: 32),
                StrictDispenseRequestUnitLengthRule(maxLength: 64),
            ]
        )
    }
}
