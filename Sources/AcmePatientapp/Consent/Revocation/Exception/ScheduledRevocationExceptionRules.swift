import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled revocation exception must pass. Check returns its problems, or none.
    protocol ScheduledRevocationExceptionRule {
        func check(_ item: ScheduledRevocationException) -> [String]
    }

    final class ScheduledRevocationExceptionAllowedCategoryRule: ScheduledRevocationExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledRevocationException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is out of range"]
            }
            return []
        }
    }

    final class ScheduledRevocationExceptionNameLengthRule: ScheduledRevocationExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledRevocationException) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledRevocationExceptionCeilingRangeRule: ScheduledRevocationExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRevocationException) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledRevocationExceptionSegmentLengthRule: ScheduledRevocationExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledRevocationException) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledRevocationExceptionRequiredCategoryRule: ScheduledRevocationExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRevocationException) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledRevocationExceptionRequiredCodeRule: ScheduledRevocationExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRevocationException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled revocation exception.
    final class ScheduledRevocationExceptionValidator {
        var rules: [any ScheduledRevocationExceptionRule]

        init(rules: [any ScheduledRevocationExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledRevocationException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledRevocationException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledRevocationException]) -> [String: [String]] {
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

    static func defaultScheduledRevocationExceptionValidator() -> ScheduledRevocationExceptionValidator {
        return ScheduledRevocationExceptionValidator(
            rules: [
                ScheduledRevocationExceptionAllowedCategoryRule(allowed: []),
                ScheduledRevocationExceptionNameLengthRule(maxLength: 86400),
                ScheduledRevocationExceptionCeilingRangeRule(min: 3.1, max: 815.4),
                ScheduledRevocationExceptionSegmentLengthRule(maxLength: 1000),
                ScheduledRevocationExceptionRequiredCategoryRule(
                    message: "scheduled revocation exception needs this field"
                ),
                ScheduledRevocationExceptionRequiredCodeRule(
                    message: "scheduled revocation exception needs this field"
                ),
            ]
        )
    }
}
