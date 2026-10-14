import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool draft must pass. Check returns its problems, or none.
    protocol FloatPoolDraftRule {
        func check(_ item: FloatPoolDraft) -> [String]
    }

    final class FloatPoolDraftNameLengthRule: FloatPoolDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolDraftAllowedNameRule: FloatPoolDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is above maximum"]
            }
            return []
        }
    }

    final class FloatPoolDraftDiscountRangeRule: FloatPoolDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolDraft) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a float pool draft.
    final class FloatPoolDraftValidator {
        var rules: [any FloatPoolDraftRule]

        init(rules: [any FloatPoolDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolDraft]) -> [String: [String]] {
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

    static func defaultFloatPoolDraftValidator() -> FloatPoolDraftValidator {
        return FloatPoolDraftValidator(
            rules: [
                FloatPoolDraftNameLengthRule(maxLength: 32),
                FloatPoolDraftAllowedNameRule(allowed: ["tiered", "scheduled", "default"]),
                FloatPoolDraftDiscountRangeRule(min: 6.5, max: 3339.9),
            ]
        )
    }
}
