import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier draft must pass. Check returns its problems, or none.
    protocol CourierDraftRule {
        func check(_ item: CourierDraft) -> [String]
    }

    final class CourierDraftRequiredUnitRule: CourierDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierDraft) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierDraftNameLengthRule: CourierDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierDraftMaximumRangeRule: CourierDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierDraft) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CourierDraftAllowedNameRule: CourierDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class CourierDraftUnitLengthRule: CourierDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierDraft) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierDraftWeightRangeRule: CourierDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierDraft) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a courier draft.
    final class CourierDraftValidator {
        var rules: [any CourierDraftRule]

        init(rules: [any CourierDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierDraft]) -> [String: [String]] {
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

    static func defaultCourierDraftValidator() -> CourierDraftValidator {
        return CourierDraftValidator(
            rules: [
                CourierDraftRequiredUnitRule(message: "courier draft needs this field"),
                CourierDraftNameLengthRule(maxLength: 64),
                CourierDraftMaximumRangeRule(min: 5.7, max: 277.6),
                CourierDraftAllowedNameRule(allowed: ["lenient", "fallback", "legacy"]),
                CourierDraftUnitLengthRule(maxLength: 86400),
                CourierDraftWeightRangeRule(min: 2.3, max: 842.0),
            ]
        )
    }
}
