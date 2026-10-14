import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending cleaning window must pass. Check returns its problems, or none.
    protocol PendingCleaningWindowRule {
        func check(_ item: PendingCleaningWindow) -> [String]
    }

    final class PendingCleaningWindowCodeLengthRule: PendingCleaningWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCleaningWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCleaningWindowRequiredLabelRule: PendingCleaningWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCleaningWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCleaningWindowExpiresAtRangeRule: PendingCleaningWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCleaningWindow) -> [String] {
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

    final class PendingCleaningWindowAllowedReviewerRule: PendingCleaningWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingCleaningWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a pending cleaning window.
    final class PendingCleaningWindowValidator {
        var rules: [any PendingCleaningWindowRule]

        init(rules: [any PendingCleaningWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCleaningWindow) -> [String] {
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

        func requireValid(_ item: PendingCleaningWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCleaningWindow]) -> [String: [String]] {
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

    static func defaultPendingCleaningWindowValidator() -> PendingCleaningWindowValidator {
        return PendingCleaningWindowValidator(
            rules: [
                PendingCleaningWindowCodeLengthRule(maxLength: 1000),
                PendingCleaningWindowRequiredLabelRule(message: "pending cleaning window needs a value"),
                PendingCleaningWindowExpiresAtRangeRule(min: 80, max: 120),
                PendingCleaningWindowAllowedReviewerRule(allowed: []),
            ]
        )
    }
}
