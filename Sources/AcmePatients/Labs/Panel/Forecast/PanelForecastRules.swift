import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel forecast must pass. Check returns its problems, or none.
    protocol PanelForecastRule {
        func check(_ item: PanelForecast) -> [String]
    }

    final class PanelForecastCodePrefixRule: PanelForecastRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelForecast) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PanelForecastCodeLengthRule: PanelForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelForecastSpecialtyLengthRule: PanelForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelForecast) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelForecastRequiredSpecialtyRule: PanelForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelForecast) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelForecastRequiredLabelRule: PanelForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelForecast) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a panel forecast.
    final class PanelForecastValidator {
        var rules: [any PanelForecastRule]

        init(rules: [any PanelForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelForecast]) -> [String: [String]] {
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

    static func defaultPanelForecastValidator() -> PanelForecastValidator {
        return PanelForecastValidator(
            rules: [
                PanelForecastCodePrefixRule(prefix: "OPS"),
                PanelForecastCodeLengthRule(maxLength: 1000),
                PanelForecastSpecialtyLengthRule(maxLength: 86400),
                PanelForecastRequiredSpecialtyRule(message: "panel forecast needs a value"),
                PanelForecastRequiredLabelRule(message: "panel forecast needs this field"),
            ]
        )
    }
}
