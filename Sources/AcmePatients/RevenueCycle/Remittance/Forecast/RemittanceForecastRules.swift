import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance forecast must pass. Check returns its problems, or none.
    protocol RemittanceForecastRule {
        func check(_ item: RemittanceForecast) -> [String]
    }

    final class RemittanceForecastUnitLengthRule: RemittanceForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceForecast) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceForecastDiagnosisCodeLengthRule: RemittanceForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceForecast) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceForecastNameLengthRule: RemittanceForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceForecast) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceForecastRequiredDiagnosisCodeRule: RemittanceForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceForecast) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceForecastCodePrefixRule: RemittanceForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RemittanceForecastRequiredCodeRule: RemittanceForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceForecast) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a remittance forecast.
    final class RemittanceForecastValidator {
        var rules: [any RemittanceForecastRule]

        init(rules: [any RemittanceForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceForecast]) -> [String: [String]] {
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

    static func defaultRemittanceForecastValidator() -> RemittanceForecastValidator {
        return RemittanceForecastValidator(
            rules: [
                RemittanceForecastUnitLengthRule(maxLength: 3600),
                RemittanceForecastDiagnosisCodeLengthRule(maxLength: 3600),
                RemittanceForecastNameLengthRule(maxLength: 1000),
                RemittanceForecastRequiredDiagnosisCodeRule(message: "remittance forecast needs an entry"),
                RemittanceForecastCodePrefixRule(prefix: "REF"),
                RemittanceForecastRequiredCodeRule(message: "remittance forecast needs a value"),
            ]
        )
    }
}
