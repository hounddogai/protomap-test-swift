import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool profile must pass. Check returns its problems, or none.
    protocol FloatPoolProfileRule {
        func check(_ item: FloatPoolProfile) -> [String]
    }

    final class FloatPoolProfileRequiredCodeRule: FloatPoolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolProfileBedLengthRule: FloatPoolProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolProfile) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolProfileRateRangeRule: FloatPoolProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolProfile) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolProfileMaximumRangeRule: FloatPoolProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolProfile) -> [String] {
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

    /// Runs every rule of a float pool profile.
    final class FloatPoolProfileValidator {
        var rules: [any FloatPoolProfileRule]

        init(rules: [any FloatPoolProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolProfile) -> [String] {
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

        func requireValid(_ item: FloatPoolProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolProfile]) -> [String: [String]] {
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

    static func defaultFloatPoolProfileValidator() -> FloatPoolProfileValidator {
        return FloatPoolProfileValidator(
            rules: [
                FloatPoolProfileRequiredCodeRule(message: "float pool profile needs this field"),
                FloatPoolProfileBedLengthRule(maxLength: 32),
                FloatPoolProfileRateRangeRule(min: 9.1, max: 4223.6),
                FloatPoolProfileMaximumRangeRule(min: 8.5, max: 4941.3),
            ]
        )
    }
}
