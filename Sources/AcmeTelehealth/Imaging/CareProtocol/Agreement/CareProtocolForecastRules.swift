import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol forecast must pass. Check returns its problems, or none.
    protocol CareProtocolForecastRule {
        func check(_ item: CareProtocolForecast) -> [String]
    }

    final class CareProtocolForecastAllowedProcedureCodeRule: CareProtocolForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is expired"]
            }
            return []
        }
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

    final class CareProtocolForecastCodePrefixRule: CareProtocolForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareProtocolForecastRequiredCodeRule: CareProtocolForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolForecastRequiredProcedureCodeRule: CareProtocolForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolForecast) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolForecastRequiredNameRule: CareProtocolForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolForecast) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
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
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
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
                CareProtocolForecastAllowedProcedureCodeRule(allowed: ["lenient", "manual"]),
                CareProtocolForecastCodeLengthRule(maxLength: 86400),
                CareProtocolForecastCodePrefixRule(prefix: "REF"),
                CareProtocolForecastRequiredCodeRule(message: "care protocol forecast needs this field"),
                CareProtocolForecastRequiredProcedureCodeRule(message: "care protocol forecast needs an entry"),
                CareProtocolForecastRequiredNameRule(message: "care protocol forecast needs this field"),
            ]
        )
    }
}
