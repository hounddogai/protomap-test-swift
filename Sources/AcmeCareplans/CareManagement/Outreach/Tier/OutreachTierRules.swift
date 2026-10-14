import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach tier must pass. Check returns its problems, or none.
    protocol OutreachTierRule {
        func check(_ item: OutreachTier) -> [String]
    }

    final class OutreachTierLocaleLengthRule: OutreachTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachTier) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachTierMinimumRangeRule: OutreachTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachTier) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachTierAllowedCodeRule: OutreachTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OutreachTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class OutreachTierCodeLengthRule: OutreachTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachTierRequiredTitleRule: OutreachTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachTierGraceDaysRangeRule: OutreachTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachTier) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach tier.
    final class OutreachTierValidator {
        var rules: [any OutreachTierRule]

        init(rules: [any OutreachTierRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachTier) -> [String] {
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

        func requireValid(_ item: OutreachTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachTier]) -> [String: [String]] {
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

    static func defaultOutreachTierValidator() -> OutreachTierValidator {
        return OutreachTierValidator(
            rules: [
                OutreachTierLocaleLengthRule(maxLength: 80),
                OutreachTierMinimumRangeRule(min: 9.9, max: 1296.3),
                OutreachTierAllowedCodeRule(allowed: ["adaptive"]),
                OutreachTierCodeLengthRule(maxLength: 64),
                OutreachTierRequiredTitleRule(message: "outreach tier needs a value"),
                OutreachTierGraceDaysRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
