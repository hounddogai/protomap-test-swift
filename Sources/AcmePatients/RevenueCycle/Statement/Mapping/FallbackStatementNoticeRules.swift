import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback statement notice must pass. Check returns its problems, or none.
    protocol FallbackStatementNoticeRule {
        func check(_ item: FallbackStatementNotice) -> [String]
    }

    final class FallbackStatementNoticeCeilingRangeRule: FallbackStatementNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackStatementNotice) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackStatementNoticeRequiredLocaleRule: FallbackStatementNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackStatementNotice) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackStatementNoticeCodePrefixRule: FallbackStatementNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackStatementNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackStatementNoticePriorityRangeRule: FallbackStatementNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackStatementNotice) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback statement notice.
    final class FallbackStatementNoticeValidator {
        var rules: [any FallbackStatementNoticeRule]

        init(rules: [any FallbackStatementNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackStatementNotice) -> [String] {
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

        func requireValid(_ item: FallbackStatementNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackStatementNotice]) -> [String: [String]] {
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

    static func defaultFallbackStatementNoticeValidator() -> FallbackStatementNoticeValidator {
        return FallbackStatementNoticeValidator(
            rules: [
                FallbackStatementNoticeCeilingRangeRule(min: 3.5, max: 2803.9),
                FallbackStatementNoticeRequiredLocaleRule(message: "fallback statement notice needs an entry"),
                FallbackStatementNoticeCodePrefixRule(prefix: "OPS"),
                FallbackStatementNoticePriorityRangeRule(min: 64, max: 255),
            ]
        )
    }
}
