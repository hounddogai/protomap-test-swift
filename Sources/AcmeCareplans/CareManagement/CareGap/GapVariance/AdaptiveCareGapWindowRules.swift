import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive care gap window must pass. Check returns its problems, or none.
    protocol AdaptiveCareGapWindowRule {
        func check(_ item: AdaptiveCareGapWindow) -> [String]
    }

    final class AdaptiveCareGapWindowAllowedUnitRule: AdaptiveCareGapWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveCareGapWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is inconsistent"]
            }
            return []
        }
    }

    final class AdaptiveCareGapWindowRequiredCodeRule: AdaptiveCareGapWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCareGapWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCareGapWindowGraceDaysRangeRule: AdaptiveCareGapWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCareGapWindow) -> [String] {
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

    final class AdaptiveCareGapWindowLocaleLengthRule: AdaptiveCareGapWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCareGapWindow) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCareGapWindowRequiredLocaleRule: AdaptiveCareGapWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCareGapWindow) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive care gap window.
    final class AdaptiveCareGapWindowValidator {
        var rules: [any AdaptiveCareGapWindowRule]

        init(rules: [any AdaptiveCareGapWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCareGapWindow) -> [String] {
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

        func requireValid(_ item: AdaptiveCareGapWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCareGapWindow]) -> [String: [String]] {
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

    static func defaultAdaptiveCareGapWindowValidator() -> AdaptiveCareGapWindowValidator {
        return AdaptiveCareGapWindowValidator(
            rules: [
                AdaptiveCareGapWindowAllowedUnitRule(allowed: ["scheduled"]),
                AdaptiveCareGapWindowRequiredCodeRule(message: "adaptive care gap window needs a value"),
                AdaptiveCareGapWindowGraceDaysRangeRule(min: 255, max: 255),
                AdaptiveCareGapWindowLocaleLengthRule(maxLength: 64),
                AdaptiveCareGapWindowRequiredLocaleRule(message: "adaptive care gap window needs this field"),
            ]
        )
    }
}
