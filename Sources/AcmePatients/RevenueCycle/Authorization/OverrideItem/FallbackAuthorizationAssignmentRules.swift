import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback authorization assignment must pass. Check returns its problems, or none.
    protocol FallbackAuthorizationAssignmentRule {
        func check(_ item: FallbackAuthorizationAssignment) -> [String]
    }

    final class FallbackAuthorizationAssignmentAllowedCodeRule: FallbackAuthorizationAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackAuthorizationAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class FallbackAuthorizationAssignmentCodeLengthRule: FallbackAuthorizationAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAuthorizationAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAuthorizationAssignmentRequiredTitleRule: FallbackAuthorizationAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAuthorizationAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAuthorizationAssignmentVisitMinutesRangeRule: FallbackAuthorizationAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackAuthorizationAssignment) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback authorization assignment.
    final class FallbackAuthorizationAssignmentValidator {
        var rules: [any FallbackAuthorizationAssignmentRule]

        init(rules: [any FallbackAuthorizationAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackAuthorizationAssignment) -> [String] {
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

        func requireValid(_ item: FallbackAuthorizationAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackAuthorizationAssignment]) -> [String: [String]] {
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

    static func defaultFallbackAuthorizationAssignmentValidator() -> FallbackAuthorizationAssignmentValidator {
        return FallbackAuthorizationAssignmentValidator(
            rules: [
                FallbackAuthorizationAssignmentAllowedCodeRule(allowed: ["adaptive", "scheduled"]),
                FallbackAuthorizationAssignmentCodeLengthRule(maxLength: 64),
                FallbackAuthorizationAssignmentRequiredTitleRule(
                    message: "fallback authorization assignment needs a value"
                ),
                FallbackAuthorizationAssignmentVisitMinutesRangeRule(min: 1000, max: 86400),
            ]
        )
    }
}
