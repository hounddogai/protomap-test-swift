import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol forecast must pass. Check returns its problems, or none.
    protocol CareProtocolForecastRule {
        func check(_ item: CareProtocolForecast) -> [String]
    }

    final class CareProtocolForecastCodeLengthRule: CareProtocolForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolForecastTitleLengthRule: CareProtocolForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolForecast) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolForecastRequiredBedRule: CareProtocolForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolForecast) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol forecast.
    final class CareProtocolForecastValidator {
        var rules: [any CareProtocolForecastRule]

        init(rules: [any CareProtocolForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolForecast) -> [String] {
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

        func requireValid(_ item: CareProtocolForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolForecast]) -> [String: [String]] {
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

    static func defaultCareProtocolForecastValidator() -> CareProtocolForecastValidator {
        return CareProtocolForecastValidator(
            rules: [
                CareProtocolForecastCodeLengthRule(maxLength: 86400),
                CareProtocolForecastTitleLengthRule(maxLength: 255),
                CareProtocolForecastRequiredBedRule(message: "care protocol forecast needs an entry"),
            ]
        )
    }
}
