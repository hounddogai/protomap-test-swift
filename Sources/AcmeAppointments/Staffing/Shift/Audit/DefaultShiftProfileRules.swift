import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default shift profile must pass. Check returns its problems, or none.
    protocol DefaultShiftProfileRule {
        func check(_ item: DefaultShiftProfile) -> [String]
    }

    final class DefaultShiftProfileScoreRangeRule: DefaultShiftProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultShiftProfile) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultShiftProfileAllowedDescriptionRule: DefaultShiftProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultShiftProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is blocked"]
            }
            return []
        }
    }

    final class DefaultShiftProfileSegmentLengthRule: DefaultShiftProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultShiftProfile) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultShiftProfileRequiredWardRule: DefaultShiftProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultShiftProfile) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultShiftProfileRequiredLabelRule: DefaultShiftProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultShiftProfile) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default shift profile.
    final class DefaultShiftProfileValidator {
        var rules: [any DefaultShiftProfileRule]

        init(rules: [any DefaultShiftProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultShiftProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultShiftProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultShiftProfile]) -> [String: [String]] {
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

    static func defaultDefaultShiftProfileValidator() -> DefaultShiftProfileValidator {
        return DefaultShiftProfileValidator(
            rules: [
                DefaultShiftProfileScoreRangeRule(min: 1.9, max: 3926.6),
                DefaultShiftProfileAllowedDescriptionRule(allowed: ["weighted", "scheduled"]),
                DefaultShiftProfileSegmentLengthRule(maxLength: 120),
                DefaultShiftProfileRequiredWardRule(message: "default shift profile needs an entry"),
                DefaultShiftProfileRequiredLabelRule(message: "default shift profile needs an entry"),
            ]
        )
    }
}
