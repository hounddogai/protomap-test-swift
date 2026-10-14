import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive transfer schedule must pass. Check returns its problems, or none.
    protocol AdaptiveTransferScheduleRule {
        func check(_ item: AdaptiveTransferSchedule) -> [String]
    }

    final class AdaptiveTransferScheduleCodePrefixRule: AdaptiveTransferScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveTransferSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveTransferScheduleRequiredTitleRule: AdaptiveTransferScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveTransferSchedule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveTransferScheduleDiscountRangeRule: AdaptiveTransferScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveTransferSchedule) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveTransferScheduleCurrencyLengthRule: AdaptiveTransferScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveTransferSchedule) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveTransferScheduleCodeLengthRule: AdaptiveTransferScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveTransferSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive transfer schedule.
    final class AdaptiveTransferScheduleValidator {
        var rules: [any AdaptiveTransferScheduleRule]

        init(rules: [any AdaptiveTransferScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveTransferSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveTransferSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveTransferSchedule]) -> [String: [String]] {
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

    static func defaultAdaptiveTransferScheduleValidator() -> AdaptiveTransferScheduleValidator {
        return AdaptiveTransferScheduleValidator(
            rules: [
                AdaptiveTransferScheduleCodePrefixRule(prefix: "OPS"),
                AdaptiveTransferScheduleRequiredTitleRule(message: "adaptive transfer schedule needs an entry"),
                AdaptiveTransferScheduleDiscountRangeRule(min: 9.8, max: 1394.8),
                AdaptiveTransferScheduleCurrencyLengthRule(maxLength: 255),
                AdaptiveTransferScheduleCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
