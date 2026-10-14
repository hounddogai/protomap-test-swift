import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool plan must pass. Check returns its problems, or none.
    protocol FloatPoolPlanRule {
        func check(_ item: FloatPoolPlan) -> [String]
    }

    final class FloatPoolPlanPayerLengthRule: FloatPoolPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolPlan) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolPlanCodeLengthRule: FloatPoolPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolPlanRequiredTitleRule: FloatPoolPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolPlanRequiredCodeRule: FloatPoolPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolPlanAllowedTitleRule: FloatPoolPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class FloatPoolPlanRegionLengthRule: FloatPoolPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolPlan) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool plan.
    final class FloatPoolPlanValidator {
        var rules: [any FloatPoolPlanRule]

        init(rules: [any FloatPoolPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolPlan]) -> [String: [String]] {
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

    static func defaultFloatPoolPlanValidator() -> FloatPoolPlanValidator {
        return FloatPoolPlanValidator(
            rules: [
                FloatPoolPlanPayerLengthRule(maxLength: 32),
                FloatPoolPlanCodeLengthRule(maxLength: 3600),
                FloatPoolPlanRequiredTitleRule(message: "float pool plan needs an entry"),
                FloatPoolPlanRequiredCodeRule(message: "float pool plan needs this field"),
                FloatPoolPlanAllowedTitleRule(allowed: []),
                FloatPoolPlanRegionLengthRule(maxLength: 3600),
            ]
        )
    }
}
