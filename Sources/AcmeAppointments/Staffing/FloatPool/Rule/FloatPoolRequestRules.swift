import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool request must pass. Check returns its problems, or none.
    protocol FloatPoolRequestRule {
        func check(_ item: FloatPoolRequest) -> [String]
    }

    final class FloatPoolRequestDiscountRangeRule: FloatPoolRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolRequest) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FloatPoolRequestDurationMinutesRangeRule: FloatPoolRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolRequest) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolRequestRequiredCountryRule: FloatPoolRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolRequest) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolRequestCodeLengthRule: FloatPoolRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolRequestCountryLengthRule: FloatPoolRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolRequest) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolRequestCodePrefixRule: FloatPoolRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FloatPoolRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool request.
    final class FloatPoolRequestValidator {
        var rules: [any FloatPoolRequestRule]

        init(rules: [any FloatPoolRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolRequest]) -> [String: [String]] {
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

    static func defaultFloatPoolRequestValidator() -> FloatPoolRequestValidator {
        return FloatPoolRequestValidator(
            rules: [
                FloatPoolRequestDiscountRangeRule(min: 7.3, max: 2017.0),
                FloatPoolRequestDurationMinutesRangeRule(min: 32, max: 32),
                FloatPoolRequestRequiredCountryRule(message: "float pool request needs an entry"),
                FloatPoolRequestCodeLengthRule(maxLength: 32),
                FloatPoolRequestCountryLengthRule(maxLength: 64),
                FloatPoolRequestCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
