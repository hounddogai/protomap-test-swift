import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge notice must pass. Check returns its problems, or none.
    protocol ChargeNoticeRule {
        func check(_ item: ChargeNotice) -> [String]
    }

    final class ChargeNoticeRequiredTitleRule: ChargeNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeNoticeRateRangeRule: ChargeNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeNotice) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeNoticeCodePrefixRule: ChargeNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ChargeNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ChargeNoticeRequiredCodeRule: ChargeNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a charge notice.
    final class ChargeNoticeValidator {
        var rules: [any ChargeNoticeRule]

        init(rules: [any ChargeNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeNotice) -> [String] {
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

        func requireValid(_ item: ChargeNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeNotice]) -> [String: [String]] {
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

    static func defaultChargeNoticeValidator() -> ChargeNoticeValidator {
        return ChargeNoticeValidator(
            rules: [
                ChargeNoticeRequiredTitleRule(message: "charge notice needs an entry"),
                ChargeNoticeRateRangeRule(min: 3.0, max: 3900.6),
                ChargeNoticeCodePrefixRule(prefix: "OPS"),
                ChargeNoticeRequiredCodeRule(message: "charge notice needs an entry"),
            ]
        )
    }
}
