import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality forecast must pass. Check returns its problems, or none.
    protocol ModalityForecastRule {
        func check(_ item: ModalityForecast) -> [String]
    }

    final class ModalityForecastWardLengthRule: ModalityForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityForecast) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityForecastCodeLengthRule: ModalityForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityForecastNotesLengthRule: ModalityForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityForecast) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityForecastPriorityRangeRule: ModalityForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityForecast) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ModalityForecastGraceDaysRangeRule: ModalityForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalityForecast) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality forecast.
    final class ModalityForecastValidator {
        var rules: [any ModalityForecastRule]

        init(rules: [any ModalityForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityForecast) -> [String] {
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

        func requireValid(_ item: ModalityForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityForecast]) -> [String: [String]] {
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

    static func defaultModalityForecastValidator() -> ModalityForecastValidator {
        return ModalityForecastValidator(
            rules: [
                ModalityForecastWardLengthRule(maxLength: 1000),
                ModalityForecastCodeLengthRule(maxLength: 3600),
                ModalityForecastNotesLengthRule(maxLength: 1000),
                ModalityForecastPriorityRangeRule(min: 255, max: 3600),
                ModalityForecastGraceDaysRangeRule(min: 120, max: 3600),
            ]
        )
    }
}
