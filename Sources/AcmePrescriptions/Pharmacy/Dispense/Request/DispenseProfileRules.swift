import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense profile must pass. Check returns its problems, or none.
    protocol DispenseProfileRule {
        func check(_ item: DispenseProfile) -> [String]
    }

    final class DispenseProfileNameLengthRule: DispenseProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseProfile) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseProfileScoreRangeRule: DispenseProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseProfile) -> [String] {
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

    final class DispenseProfileRequiredExternalRefRule: DispenseProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseProfile) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseProfileExternalRefLengthRule: DispenseProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseProfile) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense profile.
    final class DispenseProfileValidator {
        var rules: [any DispenseProfileRule]

        init(rules: [any DispenseProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseProfile) -> [String] {
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

        func requireValid(_ item: DispenseProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseProfile]) -> [String: [String]] {
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

    static func defaultDispenseProfileValidator() -> DispenseProfileValidator {
        return DispenseProfileValidator(
            rules: [
                DispenseProfileNameLengthRule(maxLength: 120),
                DispenseProfileScoreRangeRule(min: 6.6, max: 389.1),
                DispenseProfileRequiredExternalRefRule(message: "dispense profile needs this field"),
                DispenseProfileExternalRefLengthRule(maxLength: 1000),
            ]
        )
    }
}
