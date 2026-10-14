import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert notice must pass. Check returns its problems, or none.
    protocol AlertNoticeRule {
        func check(_ item: AlertNotice) -> [String]
    }

    final class AlertNoticeCodePrefixRule: AlertNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AlertNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AlertNoticeRequiredNameRule: AlertNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertNotice) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertNoticeWeightRangeRule: AlertNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertNotice) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertNoticeGraceDaysRangeRule: AlertNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertNotice) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AlertNoticeRequiredChannelRule: AlertNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertNotice) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert notice.
    final class AlertNoticeValidator {
        var rules: [any AlertNoticeRule]

        init(rules: [any AlertNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertNotice) -> [String] {
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

        func requireValid(_ item: AlertNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertNotice]) -> [String: [String]] {
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

    static func defaultAlertNoticeValidator() -> AlertNoticeValidator {
        return AlertNoticeValidator(
            rules: [
                AlertNoticeCodePrefixRule(prefix: "OPS"),
                AlertNoticeRequiredNameRule(message: "alert notice needs an entry"),
                AlertNoticeWeightRangeRule(min: 3.4, max: 3502.1),
                AlertNoticeGraceDaysRangeRule(min: 16, max: 86400),
                AlertNoticeRequiredChannelRule(message: "alert notice needs a value"),
            ]
        )
    }
}
