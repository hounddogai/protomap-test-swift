import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback panel profile must pass. Check returns its problems, or none.
    protocol FallbackPanelProfileRule {
        func check(_ item: FallbackPanelProfile) -> [String]
    }

    final class FallbackPanelProfileLabelLengthRule: FallbackPanelProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackPanelProfile) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackPanelProfileRequiredTitleRule: FallbackPanelProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPanelProfile) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPanelProfileAllowedTitleRule: FallbackPanelProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackPanelProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is stale"]
            }
            return []
        }
    }

    final class FallbackPanelProfileRequiredSpecialtyRule: FallbackPanelProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPanelProfile) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPanelProfileRevisionRangeRule: FallbackPanelProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackPanelProfile) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackPanelProfileDosageMgRangeRule: FallbackPanelProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackPanelProfile) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback panel profile.
    final class FallbackPanelProfileValidator {
        var rules: [any FallbackPanelProfileRule]

        init(rules: [any FallbackPanelProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackPanelProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackPanelProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackPanelProfile]) -> [String: [String]] {
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

    static func defaultFallbackPanelProfileValidator() -> FallbackPanelProfileValidator {
        return FallbackPanelProfileValidator(
            rules: [
                FallbackPanelProfileLabelLengthRule(maxLength: 32),
                FallbackPanelProfileRequiredTitleRule(message: "fallback panel profile needs a value"),
                FallbackPanelProfileAllowedTitleRule(allowed: ["rolling", "default", "scheduled"]),
                FallbackPanelProfileRequiredSpecialtyRule(message: "fallback panel profile needs an entry"),
                FallbackPanelProfileRevisionRangeRule(min: 80, max: 120),
                FallbackPanelProfileDosageMgRangeRule(min: 1.0, max: 1961.8),
            ]
        )
    }
}
