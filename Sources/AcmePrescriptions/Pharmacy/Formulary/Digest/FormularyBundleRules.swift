import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary bundle must pass. Check returns its problems, or none.
    protocol FormularyBundleRule {
        func check(_ item: FormularyBundle) -> [String]
    }

    final class FormularyBundleCopayRangeRule: FormularyBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyBundle) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FormularyBundleCodeLengthRule: FormularyBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyBundleThresholdRangeRule: FormularyBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyBundle) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularyBundleNameLengthRule: FormularyBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyBundleVersionRangeRule: FormularyBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyBundle) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a formulary bundle.
    final class FormularyBundleValidator {
        var rules: [any FormularyBundleRule]

        init(rules: [any FormularyBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyBundle) -> [String] {
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

        func requireValid(_ item: FormularyBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyBundle]) -> [String: [String]] {
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

    static func defaultFormularyBundleValidator() -> FormularyBundleValidator {
        return FormularyBundleValidator(
            rules: [
                FormularyBundleCopayRangeRule(min: 4.0, max: 3997.0),
                FormularyBundleCodeLengthRule(maxLength: 120),
                FormularyBundleThresholdRangeRule(min: 5.2, max: 2535.8),
                FormularyBundleNameLengthRule(maxLength: 1000),
                FormularyBundleVersionRangeRule(min: 16, max: 255),
            ]
        )
    }
}
