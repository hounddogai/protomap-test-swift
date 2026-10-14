import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert mapping must pass. Check returns its problems, or none.
    protocol AlertMappingRule {
        func check(_ item: AlertMapping) -> [String]
    }

    final class AlertMappingCodePrefixRule: AlertMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AlertMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AlertMappingCeilingRangeRule: AlertMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertMapping) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertMappingTitleLengthRule: AlertMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertMapping) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertMappingMaximumRangeRule: AlertMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertMapping) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertMappingPhoneLengthRule: AlertMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertMapping) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertMappingRequiredPhoneRule: AlertMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertMapping) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert mapping.
    final class AlertMappingValidator {
        var rules: [any AlertMappingRule]

        init(rules: [any AlertMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertMapping]) -> [String: [String]] {
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

    static func defaultAlertMappingValidator() -> AlertMappingValidator {
        return AlertMappingValidator(
            rules: [
                AlertMappingCodePrefixRule(prefix: "X"),
                AlertMappingCeilingRangeRule(min: 5.7, max: 586.2),
                AlertMappingTitleLengthRule(maxLength: 1000),
                AlertMappingMaximumRangeRule(min: 3.1, max: 3456.9),
                AlertMappingPhoneLengthRule(maxLength: 86400),
                AlertMappingRequiredPhoneRule(message: "alert mapping needs an entry"),
            ]
        )
    }
}
