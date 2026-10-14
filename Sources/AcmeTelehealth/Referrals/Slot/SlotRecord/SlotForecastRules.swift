import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot forecast must pass. Check returns its problems, or none.
    protocol SlotForecastRule {
        func check(_ item: SlotForecast) -> [String]
    }

    final class SlotForecastSpecialtyLengthRule: SlotForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotForecast) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotForecastRequiredNameRule: SlotForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotForecast) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotForecastMaximumRangeRule: SlotForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotForecast) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotForecastContactEmailLengthRule: SlotForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotForecast) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotForecastCodePrefixRule: SlotForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SlotForecastRequiredCodeRule: SlotForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a slot forecast.
    final class SlotForecastValidator {
        var rules: [any SlotForecastRule]

        init(rules: [any SlotForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotForecast) -> [String] {
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

        func requireValid(_ item: SlotForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotForecast]) -> [String: [String]] {
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

    static func defaultSlotForecastValidator() -> SlotForecastValidator {
        return SlotForecastValidator(
            rules: [
                SlotForecastSpecialtyLengthRule(maxLength: 120),
                SlotForecastRequiredNameRule(message: "slot forecast needs an entry"),
                SlotForecastMaximumRangeRule(min: 0.9, max: 806.7),
                SlotForecastContactEmailLengthRule(maxLength: 3600),
                SlotForecastCodePrefixRule(prefix: "OPS"),
                SlotForecastRequiredCodeRule(message: "slot forecast needs a value"),
            ]
        )
    }
}
