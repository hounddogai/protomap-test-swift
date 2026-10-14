import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending read forecast must pass. Check returns its problems, or none.
    protocol PendingReadForecastRule {
        func check(_ item: PendingReadForecast) -> [String]
    }

    final class PendingReadForecastRequiredEncounterIDRule: PendingReadForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReadForecast) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReadForecastRequiredNameRule: PendingReadForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReadForecast) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReadForecastNameLengthRule: PendingReadForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReadForecast) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReadForecastAllowedCodeRule: PendingReadForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingReadForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class PendingReadForecastVisitMinutesRangeRule: PendingReadForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingReadForecast) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending read forecast.
    final class PendingReadForecastValidator {
        var rules: [any PendingReadForecastRule]

        init(rules: [any PendingReadForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingReadForecast) -> [String] {
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

        func requireValid(_ item: PendingReadForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingReadForecast]) -> [String: [String]] {
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

    static func defaultPendingReadForecastValidator() -> PendingReadForecastValidator {
        return PendingReadForecastValidator(
            rules: [
                PendingReadForecastRequiredEncounterIDRule(message: "pending read forecast needs a value"),
                PendingReadForecastRequiredNameRule(message: "pending read forecast needs an entry"),
                PendingReadForecastNameLengthRule(maxLength: 3600),
                PendingReadForecastAllowedCodeRule(allowed: []),
                PendingReadForecastVisitMinutesRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
