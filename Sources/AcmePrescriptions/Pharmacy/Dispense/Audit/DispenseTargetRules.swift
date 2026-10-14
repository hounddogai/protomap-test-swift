import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense target must pass. Check returns its problems, or none.
    protocol DispenseTargetRule {
        func check(_ item: DispenseTarget) -> [String]
    }

    final class DispenseTargetLabelLengthRule: DispenseTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseTargetRequiredCodeRule: DispenseTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseTargetPriorityRangeRule: DispenseTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseTarget) -> [String] {
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

    final class DispenseTargetRequiredEncounterIDRule: DispenseTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseTarget) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a dispense target.
    final class DispenseTargetValidator {
        var rules: [any DispenseTargetRule]

        init(rules: [any DispenseTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseTarget]) -> [String: [String]] {
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

    static func defaultDispenseTargetValidator() -> DispenseTargetValidator {
        return DispenseTargetValidator(
            rules: [
                DispenseTargetLabelLengthRule(maxLength: 80),
                DispenseTargetRequiredCodeRule(message: "dispense target needs a value"),
                DispenseTargetPriorityRangeRule(min: 86400, max: 86400),
                DispenseTargetRequiredEncounterIDRule(message: "dispense target needs a value"),
            ]
        )
    }
}
