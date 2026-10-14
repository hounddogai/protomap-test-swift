import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge assignment must pass. Check returns its problems, or none.
    protocol ChargeAssignmentRule {
        func check(_ item: ChargeAssignment) -> [String]
    }

    final class ChargeAssignmentSourceLengthRule: ChargeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeAssignment) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeAssignmentRateRangeRule: ChargeAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeAssignment) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ChargeAssignmentRequiredCodeRule: ChargeAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeAssignmentRequiredNameRule: ChargeAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a charge assignment.
    final class ChargeAssignmentValidator {
        var rules: [any ChargeAssignmentRule]

        init(rules: [any ChargeAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeAssignment) -> [String] {
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

        func requireValid(_ item: ChargeAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeAssignment]) -> [String: [String]] {
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

    static func defaultChargeAssignmentValidator() -> ChargeAssignmentValidator {
        return ChargeAssignmentValidator(
            rules: [
                ChargeAssignmentSourceLengthRule(maxLength: 32),
                ChargeAssignmentRateRangeRule(min: 3.1, max: 4192.4),
                ChargeAssignmentRequiredCodeRule(message: "charge assignment needs a value"),
                ChargeAssignmentRequiredNameRule(message: "charge assignment needs a value"),
            ]
        )
    }
}
