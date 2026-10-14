import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read forecast must pass. Check returns its problems, or none.
    protocol ReadForecastRule {
        func check(_ item: ReadForecast) -> [String]
    }

    final class ReadForecastCodeLengthRule: ReadForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadForecastRequiredCodeRule: ReadForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadForecastRequiredOwnerIDRule: ReadForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadForecast) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadForecastPatientRefLengthRule: ReadForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadForecast) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadForecastRequiredLabelRule: ReadForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadForecast) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadForecastLabelLengthRule: ReadForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadForecast) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a read forecast.
    final class ReadForecastValidator {
        var rules: [any ReadForecastRule]

        init(rules: [any ReadForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadForecast]) -> [String: [String]] {
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

    static func defaultReadForecastValidator() -> ReadForecastValidator {
        return ReadForecastValidator(
            rules: [
                ReadForecastCodeLengthRule(maxLength: 3600),
                ReadForecastRequiredCodeRule(message: "read forecast needs this field"),
                ReadForecastRequiredOwnerIDRule(message: "read forecast needs a value"),
                ReadForecastPatientRefLengthRule(maxLength: 64),
                ReadForecastRequiredLabelRule(message: "read forecast needs this field"),
                ReadForecastLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
