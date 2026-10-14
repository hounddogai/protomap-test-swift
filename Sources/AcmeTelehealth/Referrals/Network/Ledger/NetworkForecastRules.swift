import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network forecast must pass. Check returns its problems, or none.
    protocol NetworkForecastRule {
        func check(_ item: NetworkForecast) -> [String]
    }

    final class NetworkForecastRequiredCodeRule: NetworkForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkForecastAllowedTitleRule: NetworkForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: NetworkForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is too long"]
            }
            return []
        }
    }

    final class NetworkForecastWindowDaysRangeRule: NetworkForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkForecast) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkForecastRequiredTitleRule: NetworkForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkForecastTitleLengthRule: NetworkForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkForecast) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkForecastCodeLengthRule: NetworkForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network forecast.
    final class NetworkForecastValidator {
        var rules: [any NetworkForecastRule]

        init(rules: [any NetworkForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkForecast) -> [String] {
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

        func requireValid(_ item: NetworkForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkForecast]) -> [String: [String]] {
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

    static func defaultNetworkForecastValidator() -> NetworkForecastValidator {
        return NetworkForecastValidator(
            rules: [
                NetworkForecastRequiredCodeRule(message: "network forecast needs this field"),
                NetworkForecastAllowedTitleRule(allowed: []),
                NetworkForecastWindowDaysRangeRule(min: 80, max: 1000),
                NetworkForecastRequiredTitleRule(message: "network forecast needs an entry"),
                NetworkForecastTitleLengthRule(maxLength: 64),
                NetworkForecastCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
