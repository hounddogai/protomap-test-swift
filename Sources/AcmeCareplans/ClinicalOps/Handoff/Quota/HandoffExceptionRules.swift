import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff exception must pass. Check returns its problems, or none.
    protocol HandoffExceptionRule {
        func check(_ item: HandoffException) -> [String]
    }

    final class HandoffExceptionApprovedGuardRule: HandoffExceptionRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: HandoffException) -> [String] {
            if item.approved && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class HandoffExceptionRequiredCodeRule: HandoffExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffExceptionCodePrefixRule: HandoffExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: HandoffException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class HandoffExceptionExpiresAtRangeRule: HandoffExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffException) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class HandoffExceptionCapacityRangeRule: HandoffExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffException) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class HandoffExceptionTitleLengthRule: HandoffExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff exception.
    final class HandoffExceptionValidator {
        var rules: [any HandoffExceptionRule]

        init(rules: [any HandoffExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffException) -> [String] {
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

        func requireValid(_ item: HandoffException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffException]) -> [String: [String]] {
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

    static func defaultHandoffExceptionValidator() -> HandoffExceptionValidator {
        return HandoffExceptionValidator(
            rules: [
                HandoffExceptionApprovedGuardRule(limit: 120),
                HandoffExceptionRequiredCodeRule(message: "handoff exception needs this field"),
                HandoffExceptionCodePrefixRule(prefix: "Q"),
                HandoffExceptionExpiresAtRangeRule(min: 255, max: 3600),
                HandoffExceptionCapacityRangeRule(min: 64, max: 3600),
                HandoffExceptionTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
