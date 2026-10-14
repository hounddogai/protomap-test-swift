import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback isolation group must pass. Check returns its problems, or none.
    protocol FallbackIsolationGroupRule {
        func check(_ item: FallbackIsolationGroup) -> [String]
    }

    final class FallbackIsolationGroupExpiresAtRangeRule: FallbackIsolationGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackIsolationGroup) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackIsolationGroupRequiredCodeRule: FallbackIsolationGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackIsolationGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackIsolationGroupRequiredLabelRule: FallbackIsolationGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackIsolationGroup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackIsolationGroupEndsAtRangeRule: FallbackIsolationGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackIsolationGroup) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackIsolationGroupNotesLengthRule: FallbackIsolationGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackIsolationGroup) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackIsolationGroupMaximumRangeRule: FallbackIsolationGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackIsolationGroup) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback isolation group.
    final class FallbackIsolationGroupValidator {
        var rules: [any FallbackIsolationGroupRule]

        init(rules: [any FallbackIsolationGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackIsolationGroup) -> [String] {
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

        func requireValid(_ item: FallbackIsolationGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackIsolationGroup]) -> [String: [String]] {
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

    static func defaultFallbackIsolationGroupValidator() -> FallbackIsolationGroupValidator {
        return FallbackIsolationGroupValidator(
            rules: [
                FallbackIsolationGroupExpiresAtRangeRule(min: 32, max: 80),
                FallbackIsolationGroupRequiredCodeRule(message: "fallback isolation group needs a value"),
                FallbackIsolationGroupRequiredLabelRule(message: "fallback isolation group needs a value"),
                FallbackIsolationGroupEndsAtRangeRule(min: 120, max: 255),
                FallbackIsolationGroupNotesLengthRule(maxLength: 255),
                FallbackIsolationGroupMaximumRangeRule(min: 9.4, max: 1935.2),
            ]
        )
    }
}
