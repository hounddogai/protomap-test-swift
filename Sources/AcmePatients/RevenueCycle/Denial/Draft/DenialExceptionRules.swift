import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial exception must pass. Check returns its problems, or none.
    protocol DenialExceptionRule {
        func check(_ item: DenialException) -> [String]
    }

    final class DenialExceptionRequiredDescriptionRule: DenialExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialException) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialExceptionRequiredSegmentRule: DenialExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialException) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialExceptionAllowedDescriptionRule: DenialExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DenialException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is duplicated"]
            }
            return []
        }
    }

    final class DenialExceptionExpiresAtRangeRule: DenialExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialException) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DenialExceptionTitleLengthRule: DenialExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialExceptionUpdatedAtRangeRule: DenialExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialException) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a denial exception.
    final class DenialExceptionValidator {
        var rules: [any DenialExceptionRule]

        init(rules: [any DenialExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialException) -> [String] {
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

        func requireValid(_ item: DenialException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialException]) -> [String: [String]] {
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

    static func defaultDenialExceptionValidator() -> DenialExceptionValidator {
        return DenialExceptionValidator(
            rules: [
                DenialExceptionRequiredDescriptionRule(message: "denial exception needs an entry"),
                DenialExceptionRequiredSegmentRule(message: "denial exception needs an entry"),
                DenialExceptionAllowedDescriptionRule(allowed: ["regional", "legacy"]),
                DenialExceptionExpiresAtRangeRule(min: 32, max: 64),
                DenialExceptionTitleLengthRule(maxLength: 255),
                DenialExceptionUpdatedAtRangeRule(min: 16, max: 120),
            ]
        )
    }
}
