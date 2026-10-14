import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential forecast must pass. Check returns its problems, or none.
    protocol CredentialForecastRule {
        func check(_ item: CredentialForecast) -> [String]
    }

    final class CredentialForecastRequiredCodeRule: CredentialForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialForecastBatchSizeRangeRule: CredentialForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialForecast) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialForecastCodeLengthRule: CredentialForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialForecastArchivedGuardRule: CredentialForecastRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CredentialForecast) -> [String] {
            if item.archived && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a credential forecast.
    final class CredentialForecastValidator {
        var rules: [any CredentialForecastRule]

        init(rules: [any CredentialForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialForecast]) -> [String: [String]] {
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

    static func defaultCredentialForecastValidator() -> CredentialForecastValidator {
        return CredentialForecastValidator(
            rules: [
                CredentialForecastRequiredCodeRule(message: "credential forecast needs an entry"),
                CredentialForecastBatchSizeRangeRule(min: 32, max: 3600),
                CredentialForecastCodeLengthRule(maxLength: 80),
                CredentialForecastArchivedGuardRule(limit: 7.8),
            ]
        )
    }
}
