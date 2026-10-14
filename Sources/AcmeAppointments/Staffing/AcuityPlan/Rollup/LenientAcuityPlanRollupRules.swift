import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a lenient acuity plan rollup must pass. Check returns its problems, or none.
    protocol LenientAcuityPlanRollupRule {
        func check(_ item: LenientAcuityPlanRollup) -> [String]
    }

    final class LenientAcuityPlanRollupWindowDaysRangeRule: LenientAcuityPlanRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientAcuityPlanRollup) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientAcuityPlanRollupRequiredCodeRule: LenientAcuityPlanRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientAcuityPlanRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientAcuityPlanRollupAllowedLabelRule: LenientAcuityPlanRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientAcuityPlanRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient acuity plan rollup.
    final class LenientAcuityPlanRollupValidator {
        var rules: [any LenientAcuityPlanRollupRule]

        init(rules: [any LenientAcuityPlanRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientAcuityPlanRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientAcuityPlanRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientAcuityPlanRollup]) -> [String: [String]] {
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

    static func defaultLenientAcuityPlanRollupValidator() -> LenientAcuityPlanRollupValidator {
        return LenientAcuityPlanRollupValidator(
            rules: [
                LenientAcuityPlanRollupWindowDaysRangeRule(min: 1000, max: 3600),
                LenientAcuityPlanRollupRequiredCodeRule(message: "lenient acuity plan rollup needs a value"),
                LenientAcuityPlanRollupAllowedLabelRule(allowed: ["manual"]),
            ]
        )
    }
}
