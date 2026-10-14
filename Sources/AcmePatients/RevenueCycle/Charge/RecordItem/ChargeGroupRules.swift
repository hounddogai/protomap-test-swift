import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge group must pass. Check returns its problems, or none.
    protocol ChargeGroupRule {
        func check(_ item: ChargeGroup) -> [String]
    }

    final class ChargeGroupPatientRefLengthRule: ChargeGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeGroup) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeGroupWindowDaysRangeRule: ChargeGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeGroup) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeGroupRequiredNameRule: ChargeGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeGroup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a charge group.
    final class ChargeGroupValidator {
        var rules: [any ChargeGroupRule]

        init(rules: [any ChargeGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeGroup]) -> [String: [String]] {
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

    static func defaultChargeGroupValidator() -> ChargeGroupValidator {
        return ChargeGroupValidator(
            rules: [
                ChargeGroupPatientRefLengthRule(maxLength: 64),
                ChargeGroupWindowDaysRangeRule(min: 64, max: 80),
                ChargeGroupRequiredNameRule(message: "charge group needs an entry"),
            ]
        )
    }
}
