import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool reservation must pass. Check returns its problems, or none.
    protocol FloatPoolReservationRule {
        func check(_ item: FloatPoolReservation) -> [String]
    }

    final class FloatPoolReservationRequiredCodeRule: FloatPoolReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolReservationLabelLengthRule: FloatPoolReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolReservationCodePrefixRule: FloatPoolReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FloatPoolReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FloatPoolReservationMinimumRangeRule: FloatPoolReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolReservation) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolReservationSourceLengthRule: FloatPoolReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolReservation) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolReservationAllowedNameRule: FloatPoolReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool reservation.
    final class FloatPoolReservationValidator {
        var rules: [any FloatPoolReservationRule]

        init(rules: [any FloatPoolReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolReservation]) -> [String: [String]] {
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

    static func defaultFloatPoolReservationValidator() -> FloatPoolReservationValidator {
        return FloatPoolReservationValidator(
            rules: [
                FloatPoolReservationRequiredCodeRule(message: "float pool reservation needs a value"),
                FloatPoolReservationLabelLengthRule(maxLength: 1000),
                FloatPoolReservationCodePrefixRule(prefix: "OPS"),
                FloatPoolReservationMinimumRangeRule(min: 2.1, max: 1626.9),
                FloatPoolReservationSourceLengthRule(maxLength: 32),
                FloatPoolReservationAllowedNameRule(allowed: []),
            ]
        )
    }
}
