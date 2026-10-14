import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge profile must pass. Check returns its problems, or none.
    protocol ChargeProfileRule {
        func check(_ item: ChargeProfile) -> [String]
    }

    final class ChargeProfileLabelLengthRule: ChargeProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeProfile) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeProfilePriorityRangeRule: ChargeProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeProfile) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeProfileRequiredCodeRule: ChargeProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a charge profile.
    final class ChargeProfileValidator {
        var rules: [any ChargeProfileRule]

        init(rules: [any ChargeProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeProfile) -> [String] {
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

        func requireValid(_ item: ChargeProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeProfile]) -> [String: [String]] {
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

    static func defaultChargeProfileValidator() -> ChargeProfileValidator {
        return ChargeProfileValidator(
            rules: [
                ChargeProfileLabelLengthRule(maxLength: 64),
                ChargeProfilePriorityRangeRule(min: 16, max: 255),
                ChargeProfileRequiredCodeRule(message: "charge profile needs a value"),
            ]
        )
    }
}
