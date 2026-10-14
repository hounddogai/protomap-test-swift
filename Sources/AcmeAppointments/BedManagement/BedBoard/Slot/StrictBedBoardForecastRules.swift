import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict bed board forecast must pass. Check returns its problems, or none.
    protocol StrictBedBoardForecastRule {
        func check(_ item: StrictBedBoardForecast) -> [String]
    }

    final class StrictBedBoardForecastCodePrefixRule: StrictBedBoardForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictBedBoardForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictBedBoardForecastRequiredTitleRule: StrictBedBoardForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictBedBoardForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictBedBoardForecastRequiredPatientRefRule: StrictBedBoardForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictBedBoardForecast) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictBedBoardForecastRevisionRangeRule: StrictBedBoardForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictBedBoardForecast) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictBedBoardForecastTitleLengthRule: StrictBedBoardForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictBedBoardForecast) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict bed board forecast.
    final class StrictBedBoardForecastValidator {
        var rules: [any StrictBedBoardForecastRule]

        init(rules: [any StrictBedBoardForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictBedBoardForecast) -> [String] {
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

        func requireValid(_ item: StrictBedBoardForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictBedBoardForecast]) -> [String: [String]] {
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

    static func defaultStrictBedBoardForecastValidator() -> StrictBedBoardForecastValidator {
        return StrictBedBoardForecastValidator(
            rules: [
                StrictBedBoardForecastCodePrefixRule(prefix: "X"),
                StrictBedBoardForecastRequiredTitleRule(message: "strict bed board forecast needs a value"),
                StrictBedBoardForecastRequiredPatientRefRule(message: "strict bed board forecast needs an entry"),
                StrictBedBoardForecastRevisionRangeRule(min: 80, max: 1000),
                StrictBedBoardForecastTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
