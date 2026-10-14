import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness request must pass. Check returns its problems, or none.
    protocol WitnessRequestRule {
        func check(_ item: WitnessRequest) -> [String]
    }

    final class WitnessRequestWindowDaysRangeRule: WitnessRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessRequest) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessRequestNameLengthRule: WitnessRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessRequest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessRequestRequiredCurrencyRule: WitnessRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessRequest) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness request.
    final class WitnessRequestValidator {
        var rules: [any WitnessRequestRule]

        init(rules: [any WitnessRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessRequest) -> [String] {
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

        func requireValid(_ item: WitnessRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessRequest]) -> [String: [String]] {
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

    static func defaultWitnessRequestValidator() -> WitnessRequestValidator {
        return WitnessRequestValidator(
            rules: [
                WitnessRequestWindowDaysRangeRule(min: 32, max: 120),
                WitnessRequestNameLengthRule(maxLength: 3600),
                WitnessRequestRequiredCurrencyRule(message: "witness request needs a value"),
            ]
        )
    }
}
