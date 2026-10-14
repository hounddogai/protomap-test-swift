import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback panel group must pass. Check returns its problems, or none.
    protocol FallbackPanelGroupRule {
        func check(_ item: FallbackPanelGroup) -> [String]
    }

    final class FallbackPanelGroupRequiredNameRule: FallbackPanelGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPanelGroup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPanelGroupAllowedCodeRule: FallbackPanelGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackPanelGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class FallbackPanelGroupRequiredCodeRule: FallbackPanelGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPanelGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPanelGroupDurationMinutesRangeRule: FallbackPanelGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackPanelGroup) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackPanelGroupExpiresAtRangeRule: FallbackPanelGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackPanelGroup) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback panel group.
    final class FallbackPanelGroupValidator {
        var rules: [any FallbackPanelGroupRule]

        init(rules: [any FallbackPanelGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackPanelGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackPanelGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackPanelGroup]) -> [String: [String]] {
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

    static func defaultFallbackPanelGroupValidator() -> FallbackPanelGroupValidator {
        return FallbackPanelGroupValidator(
            rules: [
                FallbackPanelGroupRequiredNameRule(message: "fallback panel group needs an entry"),
                FallbackPanelGroupAllowedCodeRule(allowed: []),
                FallbackPanelGroupRequiredCodeRule(message: "fallback panel group needs a value"),
                FallbackPanelGroupDurationMinutesRangeRule(min: 32, max: 255),
                FallbackPanelGroupExpiresAtRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
