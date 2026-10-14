import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary cycle must pass. Check returns its problems, or none.
    protocol FormularyCycleRule {
        func check(_ item: FormularyCycle) -> [String]
    }

    final class FormularyCycleDescriptionLengthRule: FormularyCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyCycle) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyCycleMaximumRangeRule: FormularyCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyCycle) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularyCycleCodeLengthRule: FormularyCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyCyclePatientRefLengthRule: FormularyCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyCycle) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyCycleFloorValueRangeRule: FormularyCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyCycle) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a formulary cycle.
    final class FormularyCycleValidator {
        var rules: [any FormularyCycleRule]

        init(rules: [any FormularyCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyCycle]) -> [String: [String]] {
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

    static func defaultFormularyCycleValidator() -> FormularyCycleValidator {
        return FormularyCycleValidator(
            rules: [
                FormularyCycleDescriptionLengthRule(maxLength: 64),
                FormularyCycleMaximumRangeRule(min: 3.0, max: 1153.8),
                FormularyCycleCodeLengthRule(maxLength: 32),
                FormularyCyclePatientRefLengthRule(maxLength: 1000),
                FormularyCycleFloorValueRangeRule(min: 8.2, max: 1620.6),
            ]
        )
    }
}
