import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global acuity plan forecast must pass. Check returns its problems, or none.
    protocol GlobalAcuityPlanForecastRule {
        func check(_ item: GlobalAcuityPlanForecast) -> [String]
    }

    final class GlobalAcuityPlanForecastRequiredPhoneRule: GlobalAcuityPlanForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAcuityPlanForecast) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAcuityPlanForecastPayerLengthRule: GlobalAcuityPlanForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAcuityPlanForecast) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAcuityPlanForecastCodeLengthRule: GlobalAcuityPlanForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAcuityPlanForecast) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAcuityPlanForecastAllowedCodeRule: GlobalAcuityPlanForecastRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalAcuityPlanForecast) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class GlobalAcuityPlanForecastPhoneLengthRule: GlobalAcuityPlanForecastRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAcuityPlanForecast) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global acuity plan forecast.
    final class GlobalAcuityPlanForecastValidator {
        var rules: [any GlobalAcuityPlanForecastRule]

        init(rules: [any GlobalAcuityPlanForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAcuityPlanForecast) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalAcuityPlanForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAcuityPlanForecast]) -> [String: [String]] {
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

    static func defaultGlobalAcuityPlanForecastValidator() -> GlobalAcuityPlanForecastValidator {
        return GlobalAcuityPlanForecastValidator(
            rules: [
                GlobalAcuityPlanForecastRequiredPhoneRule(message: "global acuity plan forecast needs this field"),
                GlobalAcuityPlanForecastPayerLengthRule(maxLength: 64),
                GlobalAcuityPlanForecastCodeLengthRule(maxLength: 32),
                GlobalAcuityPlanForecastAllowedCodeRule(allowed: []),
                GlobalAcuityPlanForecastPhoneLengthRule(maxLength: 3600),
            ]
        )
    }
}
