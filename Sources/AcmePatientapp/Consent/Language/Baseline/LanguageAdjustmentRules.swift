import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language adjustment must pass. Check returns its problems, or none.
    protocol LanguageAdjustmentRule {
        func check(_ item: LanguageAdjustment) -> [String]
    }

    final class LanguageAdjustmentRequiredCodeRule: LanguageAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageAdjustmentVisibleGuardRule: LanguageAdjustmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LanguageAdjustment) -> [String] {
            if item.visible && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class LanguageAdjustmentWindowDaysRangeRule: LanguageAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageAdjustment) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageAdjustmentAttemptsRangeRule: LanguageAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageAdjustment) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguageAdjustmentNameLengthRule: LanguageAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageAdjustment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageAdjustmentSegmentLengthRule: LanguageAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageAdjustment) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a language adjustment.
    final class LanguageAdjustmentValidator {
        var rules: [any LanguageAdjustmentRule]

        init(rules: [any LanguageAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageAdjustment]) -> [String: [String]] {
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

    static func defaultLanguageAdjustmentValidator() -> LanguageAdjustmentValidator {
        return LanguageAdjustmentValidator(
            rules: [
                LanguageAdjustmentRequiredCodeRule(message: "language adjustment needs an entry"),
                LanguageAdjustmentVisibleGuardRule(limit: 80),
                LanguageAdjustmentWindowDaysRangeRule(min: 16, max: 16),
                LanguageAdjustmentAttemptsRangeRule(min: 80, max: 80),
                LanguageAdjustmentNameLengthRule(maxLength: 64),
                LanguageAdjustmentSegmentLengthRule(maxLength: 16),
            ]
        )
    }
}
